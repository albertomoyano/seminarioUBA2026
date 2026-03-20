import subprocess
import tkinter as tk
from tkinter import Toplevel, Label, Button

def ejecutar_git(ventana):
    try:
        subprocess.run(["git", "add", "."], check=True)
        subprocess.run(["git", "commit", "-m", "@"], check=True)
        subprocess.run(["git", "push", "-u", "origin", "main"], check=True)
        mostrar_mensaje("Proceso terminado con éxito", "Los cambios se han subido a GitHub.", ventana)
    except subprocess.CalledProcessError as e:
        mostrar_mensaje("Error", f"Hubo un problema al ejecutar los comandos de Git:\n{e}", ventana)

def mostrar_mensaje(titulo, mensaje, ventana_principal):
    ventana_mensaje = Toplevel(ventana_principal)
    ventana_mensaje.title(titulo)
    ventana_mensaje.geometry("450x200")

    etiqueta = Label(ventana_mensaje, text=mensaje)
    etiqueta.pack(pady=20)

    boton_cerrar = Button(ventana_mensaje, text="Cerrar", command=lambda: [ventana_mensaje.destroy(), ventana_principal.destroy()])
    boton_cerrar.pack(pady=10)

def confirmar_empuje():
    ventana = tk.Tk()
    ventana.title("Confirmar Empuje")
    ventana.geometry("450x200")

    etiqueta = tk.Label(ventana, text="Está a punto de hacer un empuje al repositorio de GitHub.")
    etiqueta.pack(pady=20)

    boton_aceptar = tk.Button(ventana, text="Aceptar", command=lambda: ejecutar_git(ventana))
    boton_aceptar.pack(pady=10)

    ventana.mainloop()

confirmar_empuje()
