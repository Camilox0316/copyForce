#!/bin/bash

# Verifica si se pasaron exactamente dos argumentos al script
if [ $# -ne 2 ]; then
    echo "Uso: $0 directorio_origen directorio_destino"
    exit 1
fi

# Almacena los directorios en variables para un mejor manejo
dir_origen=$1
dir_destino=$2

# Compila copy5.c con gcc y asigna el nombre del ejecutable a copyForce
gcc copy5.c -o copyForce

# Verifica si la compilación fue exitosa
if [ $? -eq 0 ]; then
    echo "Compilación exitosa."

    # Verifica si los argumentos son directorios válidos
    if [ -d "$dir_origen" ] && [ -d "$dir_destino" ]; then
        echo "Ejecutando copyForce desde $dir_origen hacia $dir_destino"
        # Mide y muestra el tiempo de ejecución de copyForce
        time ./copyForce "$dir_origen" "$dir_destino"
        
        # No es necesario verificar $? aquí, time ya ha terminado
    else
        echo "Al menos uno de los argumentos no es un directorio válido."
        exit 1
    fi

    # Ejecuta el script sc.R con Rscript
    Rscript sc.R
    
    # Verifica si la ejecución de sc.R fue exitosa
    if [ $? -eq 0 ]; then
        echo "El script sc.R se ejecutó correctamente."
    else
        echo "Hubo un error al ejecutar sc.R."
    fi
else
    echo "Error en la compilación."
    exit 1
fi
