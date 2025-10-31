from django.shortcuts import render, redirect
from django.contrib.auth.forms import UserCreationForm, AuthenticationForm
from django.contrib.auth.models import User
from django.contrib.auth import login , logout, authenticate
from django.http import HttpResponse
from django.db import IntegrityError


def recetas(request):

    from login.models import Medico

    if request.user and request.user.is_authenticated:
        if Medico.objects.filter(user=request.user).exists():
            tipo = 'medico'
            return render(request, 'recetas.html')
    return HttpResponse("No tienes permiso para ver esta página.")