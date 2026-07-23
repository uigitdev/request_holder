## 1.4.0

- All successful HTTP responses are now returned through the HTTPRequestHolderSuccessResponse class.
- Added a new statusCode property, ensuring the HTTP status code is always available for successful responses. 
- The payload property now contains the previously parsed <T> model.
- payload is now nullable to support successful backend responses that only return an HTTP status code with no response body.

## 1.3.5

- Add [port] param.

## 1.3.4

- Updated http package to 1.1.0

## 1.3.3

- Removed [foundation] usage. In order to use it in dart_frog.

## 1.3.2

- Changed the type of requestBody Map<String, dynamic> to dynamic. Previous versions are compatible. No need to change.

## 1.3.1

- Dart Format

## 1.3.0

- Created [HTTPRequestHolderErrorResponse] class to identify statusCode and body.

## 1.2.0

- Created [JSONRequestHolder] abstract class.

## 1.1.1

- Changed [settings] method structure.
  Moved [dummyResponse] option from [settings] to a new abstract method.

## 1.1.0

- Fix web compatibility

## 1.0.1

- Fix pub.dev warnings

## 1.0.0

- Initial Release
