# Cargar los datos desde el archivo CSV
datos <- read.csv("copy_log.csv", stringsAsFactors = FALSE)

# Asegurarse de que los nombres de las columnas se manejen correctamente
# Reemplaza los espacios en los nombres de las columnas por puntos si es necesario
names(datos) <- gsub(" ", ".", names(datos))

# Limpiar y convertir a numérico 'Tamaño (bytes)'
datos$`Tamaño..bytes.` <- as.numeric(gsub("[^0-9]", "", datos$`Tamaño..bytes.`))

# Limpiar y convertir a numérico 'Tiempo de copia (ms)'
datos$`Tiempo.de.copia..ms.` <- as.numeric(gsub("[^0-9.]", "", datos$`Tiempo.de.copia..ms.`))

# Revisar si hay problemas con las columnas después de la limpieza
print(head(datos$`Tamaño..bytes.`))
print(head(datos$`Tiempo.de.copia..ms.`))

# Mostrar un resumen de los datos
print(summary(datos))

# Realizar un análisis sencillo: calcular el tamaño total y el tiempo total de copia
tamaño_total <- sum(datos$`Tamaño..bytes.`, na.rm = TRUE)
tiempo_total <- sum(datos$`Tiempo.de.copia..ms.`, na.rm = TRUE)

print(paste("Tamaño total de los archivos (bytes):", tamaño_total))
print(paste("Tiempo total de copia (ms):", tiempo_total))

# Calcular el tiempo medio de copia por archivo
tiempo_promedio <- mean(datos$`Tiempo.de.copia..ms.`, na.rm = TRUE)
print(paste("Tiempo medio de copia por archivo (ms):", tiempo_promedio))

# Crear una nueva columna 'Procesos' que agrupa los datos por el PID
datos$Proceso <- as.numeric(gsub("PID ", "", datos$Proceso))
datos$Procesos <- factor(datos$Proceso)

# Calcular las métricas de rendimiento
pid_stats <- data.frame(
  PID = levels(datos$Procesos),
  TiempoTotal = by(datos$`Tiempo.de.copia..ms.`, datos$Procesos, sum),
  TiempoPromedio = by(datos$`Tiempo.de.copia..ms.`, datos$Procesos, mean),
  VelocidadPromedio = by(datos$`Tamaño..bytes.`, datos$Procesos, sum) / by(datos$`Tiempo.de.copia..ms.`, datos$Procesos, sum)
)

# Ordenar los resultados por el tiempo total
pid_stats <- pid_stats[order(pid_stats$TiempoTotal, decreasing = TRUE), ]

# Imprimir los resultados
print(pid_stats)

# Identificar el PID más utilizado
pid_mas_usado <- names(which.max(table(datos$Proceso)))
print(paste("El PID más utilizado es:", pid_mas_usado))

# Calcular el tiempo promedio de copia
tiempo_promedio <- mean(datos$`Tiempo.de.copia..ms.`)
print(paste("El tiempo promedio para copiar un archivo es:", tiempo_promedio, "milisegundos"))

# Generar visualizaciones
library(ggplot2)

ggplot(pid_stats, aes(x = PID, y = TiempoTotal)) +
  geom_bar(stat = "identity") +
  labs(title = "Tiempo Total de Ejecución por PID", x = "PID", y = "Tiempo Total (ms)") +
  theme_bw()

ggplot(pid_stats, aes(x = PID, y = TiempoPromedio)) +
  geom_bar(stat = "identity") +
  labs(title = "Tiempo Promedio de Copia por PID", x = "PID", y = "Tiempo Promedio (ms)") +
  theme_bw()

ggplot(pid_stats, aes(x = PID, y = VelocidadPromedio)) +
  geom_bar(stat = "identity") +
  labs(title = "Velocidad Promedio de Copia por PID", x = "PID", y = "Velocidad Promedio (bytes/ms)") +
  theme_bw()

