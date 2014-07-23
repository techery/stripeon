initStripe = ->
  Stripe.setPublishableKey stripePublicKey

  $("form[data-stripe-form]").submit (event) ->
    $form = $(this)

    $form.find("button").prop "disabled", true
    Stripe.card.createToken $form, stripeResponseHandler

    false

stripeResponseHandler = (status, response) ->
  $form = $("form[data-stripe-form]")
  resource = $form.data("stripe-form")

  if response.error
    $form.find("#stripe-errors").addClass 'alert-error'
    $form.find("#stripe-errors").text response.error.message
    $form.find("button").prop "disabled", false
  else
    token = response.id
    $form.append $("<input type=\"hidden\" name=\"" + resource + "[card_token]\" />").val(token)

    $form.get(0).submit()

$(document).ready initStripe
$(window).bind 'page:change', initStripe
