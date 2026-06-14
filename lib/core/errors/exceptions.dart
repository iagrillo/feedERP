class ServerException     implements Exception { final String message; const ServerException(this.message); }
class AuthException       implements Exception { final String message; const AuthException(this.message); }
class PermissionException implements Exception { final String message; const PermissionException(this.message); }
