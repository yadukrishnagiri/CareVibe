/**
 * @name Find API endpoints
 * @description Finds all Express.js route handlers in the application
 * @kind problem
 * @problem.severity recommendation
 * @id javascript/find-api-endpoints
 */

import javascript

from CallExpr routeCall, string method, string path
where
  // Look for app.get(), app.post(), etc.
  routeCall.getCalleeName() in ["get", "post", "put", "delete", "patch"] and
  // Get the HTTP method from the function name
  method = routeCall.getCalleeName().toUpperCase() and
  // Get the route path from the first argument
  path = routeCall.getArgument(0).getStringValue()
select routeCall, "Found " + method + " endpoint: " + path