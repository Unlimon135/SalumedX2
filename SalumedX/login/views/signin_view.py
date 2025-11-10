from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from django.contrib.auth import authenticate
from rest_framework_simplejwt.tokens import RefreshToken

@api_view(['POST'])
@permission_classes([AllowAny])
def signin(request):
    try:
        username = request.data.get('username')
        password = request.data.get('password')
        
        if not username or not password:
            return Response({"success": False, "error": "Usuario y contraseña son requeridos"}, status=400)
        
        user = authenticate(request, username=username, password=password)
        if user is not None:
            # Generar tokens JWT
            refresh = RefreshToken.for_user(user)
            
            return Response({
                "success": True,
                "message": "Login exitoso",
                "access": str(refresh.access_token),
                "refresh": str(refresh),
                "user": {
                    "id": user.id,
                    "username": user.username,
                    "email": user.email
                }
            })
        else:
            return Response({"success": False, "error": "El usuario o la contraseña son incorrectos"}, status=400)
    except Exception as e:
        return Response({"success": False, "error": f"Error en el servidor: {str(e)}"}, status=500)