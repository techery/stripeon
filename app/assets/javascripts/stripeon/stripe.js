var initStripe, stripeResponseHandler;

initStripe = function() {
  Stripe.setPublishableKey(stripePublicKey);

  $("form[data-stripe-form]").submit(function(event) {
    var $form;
    $form = $(this);
    $form.find("button").prop("disabled", true);

    Stripe.card.createToken($form, stripeResponseHandler);

    return false;
  });
};

stripeResponseHandler = function(status, response) {
  var $form    = $("form[data-stripe-form]");
  var resource = $form.data("stripe-form");

  if (response.error) {
    $form.find("#stripe-errors").addClass('alert-error');
    $form.find("#stripe-errors").text(response.error.message);
    $form.find("button").prop("disabled", false);
  } else {
    var token = response.id;
    $form.append($("<input type=\"hidden\" name=\"" + resource + "[card_token]\" />").val(token));

    $form.get(0).submit();
  }
};

$(document).ready(initStripe);             // Init Stripe.js
$(window).bind('page:change', initStripe); // For Turbolinks support
