from django.shortcuts import render, redirect
from django.contrib.auth.forms import UserCreationForm, AuthenticationForm
from django.contrib.auth.models import User
from django.contrib.auth import login , logout, authenticate
from django.http import HttpResponse
from django.db import IntegrityError


#no se llama logout porque luego hay conflicto entre el método y la función importada (logout)
def signout(request):
    logout(request)
    return redirect('home')