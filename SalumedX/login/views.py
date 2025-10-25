from django.shortcuts import render, redirect
from django.contrib.auth.forms import UserCreationForm, AuthenticationForm
from django.contrib.auth.models import User
from django.contrib.auth import login , logout
from django.http import HttpResponse
from django.db import IntegrityError

#IMPORTANTEEEEEEEEEEEEEEEE
#por cada render, debe haber un template (archivo html) en la carpeta templates

# Create your views here.
def home(request):
    return render(request, 'home.html')

def signup(request):  #username funciona casi como un primary key en django, si existe un usuario con ese username, no se puede crear otro por más que se use otro password

    if request.method == 'GET':
        print("enviando formulario")
        return render(request, 'signup.html', {
            'form': UserCreationForm()
        })
    else: #este caso es para POST, o sea que los datos del request no pasan por el navegador, sino que vienen directamente del formulario
        if request.POST ['password1'] == request.POST['password2']:
            try:
                #registrar usuario (crea un objeto user) / después de create_user, vas a usar como username el request.POST['username'] que es un dato extraido y el password
                user = User.objects.create_user(username = request.POST['username'], password = request.POST['password1'])
                user.save() # <---guardar el usuario en la base de datos
                login(request, user)  #logear al usuario recién creado (crear cookie de sesión)
                return redirect('tasks')
            except IntegrityError:
                #si las contraseñas son iguales pero no se puede crear el usuario, es porque ya existe un usuario con el mismo nombre
                return render(request, 'signup.html',{
                    'form': UserCreationForm,
                    "error": 'El usuario ya existe'
                }) 
        #si las contraseñas no coinciden, enviar este mensaje y no crea al usuario
        return render(request, 'signup.html',{
        'form': UserCreationForm,
        "error": 'Las contraseñas no coinciden'
        }) 


def tasks(request):
    return render(request, 'tasks.html')

#no se llama logout porque luego hay conflicto entre el método y la función importada (logout)
def signout(request):
    logout(request)
    return redirect('home')

def signin(request):
    return render(request, 'signin.html'), {
        'form': AuthenticationForm()
    }