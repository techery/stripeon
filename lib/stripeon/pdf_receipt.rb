require 'prawn'

module Stripeon
  class PdfReceipt
    def self.generate(transaction)
      user = transaction.customer
      card = transaction.credit_card

      gray_color = '777777'
      pdf = Prawn::Document.new
      pdf.font 'Helvetica'
      pdf.stroke_color '999999'
      pdf.fill_color '000000'
      pdf.define_grid(columns: 5, rows: 8, gutter: 10)

      def pdf.fill_color_in(color)
        old_color = fill_color
        fill_color color
        yield
        fill_color old_color
      end

      def pdf.fat_horizontal_rule
        3.times do
          stroke_horizontal_rule
          move_down 0.5
        end
      end

      pdf.grid(0, 0).bounding_box do
        pdf.text "Receipt", size: 22, style: :bold
      end

      pdf.grid([0.3, 0], [0.3, 1]).bounding_box do
        pdf.text "John Doe", align: :left, style: :bold
        pdf.text "#{user.email}", align: :left
      end

      pdf.grid(0.3, 3.2).bounding_box do
        # Placeholder for logo.
      end

      pdf.grid([0.3, 3.7], [0.3, 4]).bounding_box do
        pdf.text "Company Name", align: :left, style: :bold
        pdf.move_down 1
        pdf.text "Address line 1", align: :left
        pdf.move_down 1
        pdf.text "Address line 2", align: :left
      end

      pdf.fill_color_in gray_color do
        pdf.fat_horizontal_rule

        pdf.move_down 10

        items = [['', 'Date Paid', 'Amount', 'Paid By']]
        pdf.table items, header: true, column_widths: [200, 125, 65, 150],
          cell_style: { borders: [], font_style: :bold, padding: [10, 5, 10, 5], align: :center } do
            column(0).style align: :left
          end
      end

      # Content
      items = [['Service', transaction.created_at.strftime("%B %d, %Y"), "$#{transaction.amount_in_dollars}", "#{card.type}-#{card.last4}"]]
      pdf.table items, header: true, column_widths: [200, 125, 65, 150],
        cell_style: { borders: [:top, :bottom], border_color: pdf.stroke_color, padding: [10, 5, 10, 5], align: :center } do
          column(0).style align: :left
        end

      pdf.fill_color_in gray_color do
        pdf.move_down 50
        pdf.text "Thank you for using our services!", align: :center, style: :bold, size: 18
        pdf.move_down 45

        pdf.fat_horizontal_rule

        pdf.grid([3.5, 0], [3.5, 4]).bounding_box do
          pdf.text "support@example.com", align: :left, size: 10
        end

        pdf.grid([3.5, 3], [3.5, 4]).bounding_box do
          pdf.text "480-555-5555", align: :right, size: 10
        end
      end

      pdf
    end
  end
end
