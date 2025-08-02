# Email Troubleshooting Guide

## Issue: Invoice emails are not being received

### Step 1: Check Browser Console
1. Open your browser's Developer Tools (F12)
2. Go to the Console tab
3. Book a service and check for any error messages
4. Look for logs starting with "ServiceDetails:" to see what's happening

### Step 2: Test the Email Endpoint
1. Open your browser and go to: `https://npcpest.com/npc/test_email.php`
2. This will show you if the mail function is working on the server
3. Check if all tests pass

### Step 3: Check Error Logs
1. Check if the file `email_errors.log` exists in the backend folder
2. If it exists, check the contents for any error messages
3. The log will show exactly what's happening when emails are sent

### Step 4: Common Issues and Solutions

#### Issue 1: Server Mail Configuration
**Problem**: The server might not be configured to send emails
**Solution**: 
- Contact your hosting provider to enable mail sending
- Ask them to check if the `mail()` function is enabled
- Verify that sendmail or SMTP is properly configured

#### Issue 2: Email Going to Spam
**Problem**: Emails might be going to spam/junk folder
**Solution**:
- Check your spam/junk folder
- Add `noreply@npcservices.com` to your contacts
- Check if your email provider is blocking the emails

#### Issue 3: Wrong Email Address
**Problem**: The email might be going to the wrong address
**Solution**:
- Check the console logs to see what email address is being sent
- Verify the email address in your profile is correct
- Test with a different email address

#### Issue 4: Server Blocking Outgoing Emails
**Problem**: Some hosting providers block outgoing emails
**Solution**:
- Contact your hosting provider
- Ask them to allow outgoing emails from your domain
- Consider using a third-party email service (SMTP)

### Step 5: Alternative Solutions

#### Option 1: Use SMTP Instead of PHP mail()
If the server's mail function is not working, we can implement SMTP email sending using PHPMailer or similar library.

#### Option 2: Use a Third-Party Email Service
We can integrate with services like:
- SendGrid
- Mailgun
- Amazon SES
- Gmail SMTP

#### Option 3: Manual Email Sending
As a temporary solution, we can:
1. Store the invoice data in the database
2. Create an admin panel to manually send emails
3. Send emails manually when needed

### Step 6: Debugging Steps

1. **Check Console Logs**: Look for any JavaScript errors
2. **Check Network Tab**: See if the API request is being made
3. **Check Server Logs**: Look for PHP errors
4. **Test with Different Email**: Try with a Gmail or other email address
5. **Check Email Headers**: Verify the email headers are correct

### Step 7: Immediate Actions

1. **Test the email endpoint**: Visit `https://npcpest.com/npc/test_email.php`
2. **Check your spam folder**: Look for emails from `noreply@npcservices.com`
3. **Verify your email address**: Make sure it's correct in your profile
4. **Contact hosting provider**: Ask about mail server configuration

### Step 8: What to Report

If you need help, please provide:
1. Screenshots of browser console errors
2. Contents of the `email_errors.log` file
3. Results from the test email page
4. Your email address (to test with)
5. Whether you checked your spam folder

### Current Status

The email functionality has been implemented with:
- ✅ Frontend integration in ServiceDetails.tsx
- ✅ Backend API endpoint (send_invoice_email.php)
- ✅ Database logging (email_logs table)
- ✅ Error logging and debugging
- ✅ Alternative email methods

The issue is likely related to server mail configuration or email delivery.

### Next Steps

1. Test the email endpoint using the test script
2. Check server mail configuration with hosting provider
3. Consider implementing SMTP email sending as an alternative
4. Monitor error logs for specific issues 