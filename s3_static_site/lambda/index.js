'use strict';

exports.handler = async function(event) {
  var request = event.Records[0].cf.request;
  var uri = request.uri;
  
  // Sanitize user input for any dissallowed characters
  // Lowercase letters (a-z), uppercase letters (A-Z), numbers (0-9), period (.), forward slash (/), and hyphens (-) allowed
  uri = uri.replace(/[^a-zA-Z0-9\.\/-]/g, '');
    
  // Check whether the URI is missing a file name.
  if (uri.endsWith('/')) {
      request.uri += 'index.html';
  } 
  // Check whether the URI is missing a file extension.
  else if (!uri.includes('.')) {
      request.uri += '/index.html';
  }

  return request;
}
