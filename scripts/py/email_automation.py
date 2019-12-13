# -*- coding: utf-8 -*-

import win32com.client as win32
outlook = win32.Dispatch('outlook.application')

mail = outlook.CreateItem(0)
mail.To = 'bmauck@prosper.com'
mail.Subject = 'Automated Test Email'
mail.Body ="""Hi {},

This is an automated email.

Is the formatting working?

Thanks,

""".format('Brian')
# mail.HTMLBody =  #this field is optional

# To attach a file to the email (optional):
# attachment  = "Path to the attachment"
# mail.Attachments.Add(attachment)

mail.Send()
