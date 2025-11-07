from rest_framework.decorators import api_view
from rest_framework.response import Response
from django.contrib.auth import logout

@api_view(['POST'])
def signout(request):
    try:
        logout(request)
        return Response({"success": True, "message": "Sesión cerrada"})
    except Exception as e:
        return Response({"success": False, "error": f"Error en el servidor: {str(e)}"}, status=500)