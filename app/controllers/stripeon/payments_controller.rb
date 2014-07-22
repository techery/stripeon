module Stripeon
  class PaymentsController < BaseController
    def index
      @transactions = current_user.transactions.order(created_at: :desc).decorate
    end

    def show
      @transaction = current_user.transactions.where(successful: true).find params[:id]

      respond_to do |format|
        format.pdf do
          pdf = PdfReceipt.generate @transaction.decorate

          send_data pdf.render, type: "application/pdf", disposition: "inline", filename: "invoice_#{@transaction.id}.pdf"
        end
      end

    rescue
      render text: 'Forbidden', status: :forbidden and return
    end
  end
end