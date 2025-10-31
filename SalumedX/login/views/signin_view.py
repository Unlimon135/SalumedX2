from django.shortcuts import render, redirect
from django.contrib.auth.forms import UserCreationForm, AuthenticationForm
from django.contrib.auth.models import User
from django.contrib.auth import login , logout, authenticate
from django.http import HttpResponse
from django.db import IntegrityError


def signin(request):
    if request.method == 'GET':
        # Render the signin template and pass the AuthenticationForm in the context.
        # Previously this returned a tuple (response, context) which causes the
        # middleware to receive a tuple instead of an HttpResponse and fail with
        # "'tuple' object has no attribute 'get'". We must return a single
        # HttpResponse object from the view.
        return render(request, 'signin.html', {
           'form': AuthenticationForm() #si no tienes esto, no se muestra el formulario en signin.html
         })
    else:
        #vamos a autenticar al usuario, primero se pasa request, y luego se extrae username y password desde POST (el post importa una tupla de datos que puedes ver en la terminal con un print)
        user = authenticate(request, username = request.POST['username'], password = request.POST['password'])

        #arriba se extraen datos del form y va a comparar con las instancias de user que se guardaron con create_user, la variable user guarda None si no habían coincidencias con los uaurios existentes, o guarda el user si encontró coincidencia

        #Abajo se valida si user es None o no. Y en base a eso redirecciona a tasks o vuelve a signin con un mensaje de error
        if user is None:
            print(request.POST)
            return render(request, 'signin.html', {
                'form': AuthenticationForm(),
                'error': 'El usuario o la contraseña son incorrectos'
            })
        else:
            login(request, user)  #si el usuario es válido, se logea (guarda la cookie de sesión)
            return redirect('tasks')