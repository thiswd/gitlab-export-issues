require 'date'

module Utils
  def self.format_date(date_string)
    datetime = DateTime.parse(date_string)
    datetime.strftime("%B %d, %Y %H:%M")
  end
end
