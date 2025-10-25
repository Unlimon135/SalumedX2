from django.shortcuts import render, redirect
from django.contrib.auth.forms import UserCreationForm, AuthenticationForm
from django.contrib.auth.models import User
from django.contrib.auth import login , logout, authenticate
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