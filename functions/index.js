const functions = require('firebase-functions'); const { onCall } = require('firebase-functions/v2/https');
const stripe = require('stripe')('STRIPE_SECRET_KEY');

exports.createPaymentIntent = onCall(
  { secrets: ['STRIPE_SECRET_KEY'] },
  async (request) => {
    const zeroDecimalCurrencies = ['vnd', 'jpy', 'krw'];
    const currency = request.data.currency.toLowerCase();
    const amount = zeroDecimalCurrencies.includes(currency)
      ? Math.round(parseFloat(request.data.amount))
      : Math.round(parseFloat(request.data.amount) * 100);

    const paymentIntent = await stripe.paymentIntents.create({
      amount: amount,
      currency: currency,
      automatic_payment_methods: { enabled: true },
    });

    return { clientSecret: paymentIntent.client_secret };
  }
);