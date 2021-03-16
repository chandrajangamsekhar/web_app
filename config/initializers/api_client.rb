
$customer_api_url = "http://localhost:3003/api/v1/customers"

# REGEX for date format matching (yyyy-mm-dd)
DATE_REGEX = /^\d{4}-(0[1-9]|1[012])-(0[1-9]|[12][0-9]|3[01])\z/

# REGEX for loca datetime format matching (mm/dd/yyyy hh:mm:ssAM/PM +0000)
LOCALTIME_DATETIME_REGEX = /^\d{2}\/\d{2}\/\d{4} \d{2}:\d{2}:\d{2}[AP]M \+\d{4}$/
