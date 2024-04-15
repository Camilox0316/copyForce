                                                                                                    results.R                                                                                                               
# Cargar los datos desde el archivo CSV
datos <- read.csv("copy_log.csv", stringsAsFactors = FALSE)
 
# Asegurarse de que los nombres de las columnas se manejen correctamente
# Reemplaza los espacios en los nombres de las columnas por puntos si es necesario
names(datos) <- gsub(" ", ".", names(datos))
 
# Verificar y limpiar los datos antes de la conversión
# Asumiendo que quieres convertir 'Tamaño..bytes.' y 'Tiempo.de.copia..ms.' a numérico

# Limpiar y convertir a numérico 'Tamaño (bytes)'
datos$`Tamaño..bytes.` <- as.numeric(gsub("[^0-9]", "", datos$`Tamaño..bytes.`))

# Limpiar y convertir a numérico 'Tiempo de copia (ms)'
datos$`Tiempo.de.copia..ms.` <- as.numeric(gsub("[^0-9.]", "", datos$`Tiempo.de.copia..ms.`))

# Ahora, si la limpieza con gsub() resulta en una conversión a un vector vacío (numeric(0)),
# podría deberse a un patrón de gsub() incorrecto o a que los datos no son lo que esperábamos.

# Revisemos si hay problemas con las columnas después de la limpieza
print(head(datos$`Tamaño..bytes.`))
print(head(datos$`Tiempo.de.copia..ms.`))

# Si los pasos anteriores funcionan correctamente, continuamos con el análisis

# Mostrar un resumen de los datos
print(summary(datos))

# Realizar un análisis sencillo: calcular el tamaño total y el tiempo total de copia
tamaño_total <- sum(datos$`Tamaño..bytes.`, na.rm = TRUE)
tiempo_total <- sum(datos$`Tiempo.de.copia..ms.`, na.rm = TRUE)

print(paste("Tamaño total de los archivos (bytes):", tamaño_total))
print(paste("Tiempo total de copia (ms):", tiempo_total))

# Calcular el tiempo medio de copia por archivo
tiempo_medio <- mean(datos$`Tiempo.de.copia..ms.`, na.rm = TRUE)
print(paste("Tiempo medio de copia por archivo (ms):", ))
