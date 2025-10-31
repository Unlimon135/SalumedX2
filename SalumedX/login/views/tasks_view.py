from django.shortcuts import render, redirect
from django.contrib.auth.forms import UserCreationForm, AuthenticationForm
from django.contrib.auth.models import User
from django.contrib.auth import login , logout, authenticate
from django.http import HttpResponse
from django.db import IntegrityError


def tasks(request):
    # Determinar el tipo de usuario consultando si existe un perfil Medico o Paciente
    from login.models import Medico, Paciente

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