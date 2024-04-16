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
tiempo_medio <- mean(datos$`Tiempo.de.copia..ms.`, na.rm = TRUE)
print(paste("Tiempo medio de copia por archivo (ms):", tiempo_medio))

# Crear una nueva columna 'Procesos' que agrupa los datos por la cantidad de procesos
datos$Proceso <- as.numeric(gsub("PID ", "", datos$Proceso))
datos$Procesos <- factor(datos$Proceso %/% 1000)

# Calcular las métricas de rendimiento
summary_stats <- data.frame(
  Procesos = levels(datos$Procesos),
  TiempoTotal = by(datos$`Tiempo.de.copia..ms.`, datos$Procesos, sum),
  TiempoPromedio = by(datos$`Tiempo.de.copia..ms.`, datos$Procesos, mean),
  VelocidadPromedio = by(datos$`Tamaño..bytes.`, datos$Procesos, sum) / by(datos$`Tiempo.de.copia..ms.`, datos$Procesos, sum)
)

# Ordenar los resultados por el tiempo total
summary_stats <- summary_stats[order(summary_stats$TiempoTotal), ]

# Imprimir los resultados
print(summary_stats)

# Identificar el proceso más utilizado
proceso_frecuencia <- table(datos$Proceso)
proceso_mas_usado <- names(which.max(proceso_frecuencia))
print(paste("El proceso más utilizado es:", proceso_mas_usado))

# Calcular el tiempo promedio de copia
tiempo_promedio <- mean(datos$`Tiempo.de.copia..ms.`)
print(paste("El tiempo promedio para copiar un archivo es:", tiempo_promedio, "milisegundos"))

# Generar visualizaciones
library(ggplot2)

ggplot(summary_stats, aes(x = Procesos, y = TiempoTotal)) +
  geom_bar(stat = "identity") +
  labs(title = "Tiempo Total de Ejecución", x = "Cantidad de Procesos", y = "Tiempo Total (ms)") +
  theme_bw()

ggplot(summary_stats, aes(x = Procesos, y = TiempoPromedio)) +
  geom_bar(stat = "identity") +
  labs(title = "Tiempo Promedio de Copia", x = "Cantidad de Procesos", y = "Tiempo Promedio (ms)") +
  theme_bw()

ggplot(summary_stats, aes(x = Procesos, y = VelocidadPromedio)) +
  geom_bar(stat = "identity") +
  labs(title = "Velocidad Promedio de Copia", x = "Cantidad de Procesos", y = "Velocidad Promedio (bytes/ms)") +
  theme_bw()

