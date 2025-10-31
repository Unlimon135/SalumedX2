from django.shortcuts import render, redirect
from django.contrib.auth.forms import UserCreationForm, AuthenticationForm
from django.contrib.auth.models import User
from django.contrib.auth import login , logout, authenticate
from django.http import HttpResponse
from django.db import IntegrityError

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