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

    # Mantengo el comportamiento original: mostrar el formulario en GET
    if request.method == 'GET':
        print("enviando formulario")
        return render(request, 'signup.html', {
            'form': UserCreationForm()
        })

    # POST: crear usuario y perfil asociado (Paciente o Medico)
    # este bloque procesa los campos adicionales enviados desde la plantilla
    # campos esperados (opcionales según tipo): first_name, last_name, email, tipo_usuario
    if request.method == 'POST':
        if request.POST.get('password1') != request.POST.get('password2'):
            #si las contraseñas no coinciden, enviar este mensaje y no crea al usuario
            return render(request, 'signup.html', {
                'form': UserCreationForm(),
                'error': 'Las contraseñas no coinciden'
            })

        username = request.POST.get('username')
        password = request.POST.get('password1')
        first_name = request.POST.get('first_name', '')
        last_name = request.POST.get('last_name', '')
        email = request.POST.get('email', '')
        tipo = request.POST.get('tipo_usuario', 'paciente').lower()

        try:
            # crear el usuario Django
            user = User.objects.create_user(username=username, password=password,
                                            first_name=first_name, last_name=last_name, email=email)
            user.save()

            # intentar crear perfiles asociados: Medico o Paciente
            from .models import Medico, Paciente

            if tipo == 'medico':
                # campos específicos del médico (pueden venir vacíos si la plantilla no los llena)
                numero_licencia = request.POST.get('numero_licencia', '')
                institucion = request.POST.get('institucion', '')
                ubicacion = request.POST.get('ubicacion_consultorio', '')
                # crear el perfil de Medico ligado al User de Django
                Medico.objects.create(user=user, numero_licencia=numero_licencia,
                                      institucion=institucion, ubicacion_consultorio=ubicacion)

            else:
                # paciente
                fecha_nacimiento = request.POST.get('fecha_nacimiento', None)
                cedula = request.POST.get('cedula', '')
                direccion = request.POST.get('direccion', '')
                telefono = request.POST.get('telefono', '')

                # crear el perfil de Paciente ligado al User de Django
                Paciente.objects.create(user=user, fecha_nacimiento=fecha_nacimiento,
                                        cedula=cedula, direccion=direccion, telefono=telefono)

            # logear al usuario recién creado
            login(request, user)
            print("Usuario creado y logueado exitosamente:", user.username)
            return redirect('tasks')

        except IntegrityError:
            # si no se puede crear el usuario, es porque ya existe un usuario con el mismo nombre
            return render(request, 'signup.html', {
                'form': UserCreationForm(),
                'error': 'El usuario ya existe'
            })

    # por defecto, volver a mostrar el formulario
    return render(request, 'signup.html', {
        'form': UserCreationForm(),
    })


def tasks(request):
    # Determinar el tipo de usuario consultando si existe un perfil Medico o Paciente
    from .models import Medico, Paciente

    tipo = 'desconocido'
    if request.user and request.user.is_authenticated:
        if Medico.objects.filter(user=request.user).exists():
            tipo = 'medico'
        elif Paciente.objects.filter(user=request.user).exists():
            tipo = 'paciente'

    print("Accediendo a la vista tasks - tipo_usuario:", tipo)
    return render(request, 'tasks.html', {
        'user': request.user,
        'tipo_usuario': tipo,
    })

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
        

def recetas(request):

    from .models import Medico

    if request.user and request.user.is_authenticated:
        if Medico.objects.filter(user=request.user).exists():
            tipo = 'medico'
            return render(request, 'recetas.html')
    return HttpResponse("No tienes permiso para ver esta página.")