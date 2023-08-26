from fastapi import FastAPI, HTTPException, Request, Response
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import RedirectResponse
from fastapi.staticfiles import StaticFiles

from dotenv import load_dotenv
import os 
import stripe 
import resend
import hmac
import hashlib
import re

load_dotenv()

stripe.api_key = os.getenv("STRIPE_SECRET_KEY")
resend.api_key = os.getenv("RESEND_API_KEY")

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.post("/webhook")
async def post_webhook(request: Request):
    body = await request.body()  
  
    if not body:  
        return HTTPException(status_code=400)

    payload = await request.json()
    print(request.headers)
    print(payload)

    if "stripe-signature" not in request.headers:
        return HTTPException(status_code=400)
    sig_header = request.headers["stripe-signature"]

    event = None

    try:
        event = stripe.Webhook.construct_event(
            body, sig_header, os.getenv("STRIPE_WEBHOOK_SECRET")
        )
    except ValueError as e:
        # Invalid payload
        return HTTPException(status_code=400)
    except stripe.error.SignatureVerificationError as e:
        # Invalid signature
        return HTTPException(status_code=400)

    # Handle the checkout.session.completed event
    if event["type"] == "checkout.session.completed":
        try:
            email = event["data"]["object"]["customer_details"]["email"]
        except:
            print("Couldn't get email, triggering fall back email")
            r = resend.Emails.send({
                "from": "messagemate@messagemate.io",
                "to": "shekar@ramaswamy.org",
                "reply_to": "shekar@ramaswamy.org",
                "subject": "INVALID EMAIL",
                "html": f"<p>Couldnt get email for purchase. Stripe payload {payload}</p>"
            })
            print(r)
            return Response(status_code=200)
        
        try:
            client_reference_id = event["data"]["object"]["client_reference_id"]
        except:
            print("Couldn't get client reference id, triggering fall back email")
            r = resend.Emails.send({
                "from": "messagemate@messagemate.io",
                "to": "shekar@ramaswamy.org",
                "reply_to": "shekar@ramaswamy.org",
                "subject": "INVALID CLIENT REFERENCE ID",
                "html": f"<p>Couldnt get client reference id for {email}. Stripe payload {payload}</p>"
            })
            print(r)
            return Response(status_code=200)

        final_code = generate_code(client_reference_id)
        
        print("Payment was successful from " + email + " for device " + client_reference_id + " with code " + final_code)
        r = resend.Emails.send({
            "from": "messagemate@messagemate.io",
            "to": email,
            "reply_to": "shekar@ramaswamy.org",
            "subject": "Your MessageMate code is " + final_code,
            "html": f"<p>Thanks for your purchase! Your code is <strong>{final_code}</strong></p>"
        })
        print(r)
        
    return Response(status_code=200)

@app.get("/checkout-url")
def get_checkout_url(device_id: str):
    stripe_url = os.getenv("STRIPE_PAYMENT_LINK") + "?client_reference_id=" + device_id
    return {"url": stripe_url}

@app.get("/validate")
async def get_validate(device_id: str, payment_code: str):
    h = hmac.new(os.getenv("SIGNING_KEY").encode(), device_id.encode(), hashlib.sha256)
    final_code = generate_code(device_id)
    validated = final_code == payment_code

    return {"validated": validated}

def generate_code(device_id: str):
    h = hmac.new(os.getenv("SIGNING_KEY").encode(), device_id.encode(), hashlib.sha256)
    numbers = re.findall(r'\d', h.hexdigest())  
    numbers_str = ''.join(numbers)[:6].ljust(6, '0')  
    formatted_str = f"{numbers_str[:3]}-{numbers_str[3:]}"  
    return formatted_str


