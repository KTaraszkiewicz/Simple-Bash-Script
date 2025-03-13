#!/bin/bash
# Skrypt do kontroli testów wydajnościowych przy użyciu oprogramowania GeekBench6
# Autor: Krzysztof Taraszkiewicz
# Data: 2024-05-29
# Opis: Skrypt usprawnia obsługe programu GeekBench
# Licencja GeekBench wersja darmowa: FreeSource

API="Vulkan"
OPCJE="cgipd"
OPTARG=""

open_link() {
  # Check if $results file exists
  if [ ! -f "$results" ]; then
    echo "File $results does not exist."
    exit 1
  fi
  # Get the last link from the file
  link=$(head -n 2 "$results" | tail -n 1)
  # Check if the link is empty
  if [ -z "$link" ]; then
    echo "No links found in the file."
    exit 1
  fi
  # Open the last link in the default browser
  xdg-open "$link"
}

process_options() {

API="Vulkan"
  case $1 in
    g)
      # Wejście do katalogu Geekbench-6.2.1-Linux
      cd Geekbench-6.2.1-Linux
      # Tworzenie pliku tymczasowego
      tempfile=$(mktemp)
      tempfile2=$(mktemp)
      results="wynikiGPU.txt"
      touch $results
      # Uruchamianie geekbench6 --gpu-list i pobieranie nazwy API
      ./geekbench6 --gpu-list >$tempfile
      # Wyswietlenie 14 linijki
      API=$(head -n 14 $tempfile | tail -n 1)
      ./geekbench6 --gpu "$API" >$tempfile2
      # Wyświetlanie komunikatu o zakończeniu
      info="Testy benchmarku GPU zakończone.\nZaraz zostaniesz przekierowany do strony z wynikami twoich testów."
      zenity --info --title="Komunikat" --text="$info"
      # dodanie do pliku linku w celu późniejszego porównywania go
      link=$(head -n 61 $tempfile2 | tail -n 1 | tr -d ' ')
      echo "Link do wyników GPU" >$results
      echo "$link" >>$results
      open_link
      cd ..
      # Usuwanie plików tymczasowych
      rm $tempfile
      rm $tempfile2
      ;;
    c)
      # Wejście do katalogu Geekbench-6.2.1-Linux
      cd Geekbench-6.2.1-Linux
      tempfile=$(mktemp)
      results="wynikiCPU.txt"
      touch $results
      # Uruchamianie geekbench6 w trybie procesor
      ./geekbench6 --cpu >$tempfile
      info="Testy benchmarku CPU zakończone.\nZaraz zostaniesz przekierowany do strony z wynikami twoich testów."
      zenity --info --title="Komunikat" --text="$info"
      # dodanie do pliku linku w celu późniejszego porównywania go
      link=$(head -n 77 $tempfile | tail -n 1 | tr -d ' ')
      echo "Link do wyników CPU" >$results
      echo "$link" >>$results
      open_link
      cd ..
      # Usuwanie pliku tymczasowego
      rm $tempfile
      ;;
    i)
      # Wejście do katalogu Geekbench-6.2.1-Linux
      cd Geekbench-6.2.1-Linux
      # Tworzenie pliku tymczasowego
      tempfile=$(mktemp)
      ./geekbench6 --sysinfo >$tempfile
      info=$(head -n 32 $tempfile | tail -n 19)
      zenity --info --width=500 --title="Informacje o systemie" --text="$info"
      rm $tempfile
      cd ..
      ;;
    p)
      cd Geekbench-6.2.1-Linux
      if [ ! -f "wynikiGPU.txt" ] || [ ! -f "wynikiCPU.txt" ]; then
        zenity --info --title="Komunikat" --text="Niekompletne pliki z wynikami!"
        exit 1
      fi
      zenity --info --title="Komunikat" --text="Zostaną wyświetlone wyniki testów i ranking najpopularniejszych\n kart graficznych i procesorów dla osobistego porównania."
      link=$(head -n 2 "wynikiGPU.txt" | tail -n 1)
      xdg-open "$link"
      API=$(echo "$API" | tr [:upper:] [:lower:])
      xdg-open https://browser.geekbench.com/"$API"-benchmarks
      link=$(head -n 2 "wynikiCPU.txt" | tail -n 1)
      xdg-open "$link"
      xdg-open https://browser.geekbench.com/processor-benchmarks
      cd ..
      ;;
    d)
      cd Geekbench-6.2.1-Linux
      if [ ! -f "wynikiGPU.txt" ] && [ ! -f "wynikiCPU.txt" ]; then
        zenity --info --title="Komunikat" --text="Niekompletne pliki z wynikami!"
        exit 1
      fi
      zenity --info --title="Komunikat" --text="Wyniki benchmarków zostaną usunięte."
      if [ -f "wynikiGPU.txt" ]; then
        zenity --info --title="Komunikat" --text="Usunięto wynikiGPU.txt"
        rm wynikiGPU.txt
      fi
      if [ -f "wynikiCPU.txt" ]; then
        zenity --info --title="Komunikat" --text="Usunięto wynikiCPU.txt"
        rm wynikiCPU.txt
      fi
      cd ..
      ;;
    \?)
      ;;
  esac
}

while getopts "$OPCJE" opt; do
  process_options "$opt"
done

# Przetworzenie pozostałych argumentów, które nie są opcjami
shift $((OPTIND-1)) # Pominięcie przetworzonych opcji
# Sprawdzenie, czy pozostały jakieś argumenty
if [ $# -gt 0 ]; then
  echo "Nieznane argumenty: $@" >&2
  exit 1
fi

# Domyślne zachowanie, gdy skrypt zostanie uruchomiony bez żadnych opcji
if [ $OPTIND -eq 1 ]; then
  # Prosty interfejs w Zenity z listą opcji
  choice=$(zenity --list --height=300 --title="Wybierz opcję" --column="Opcja" \
    "Test GPU" \
    "Test CPU" \
    "Informacje o systemie" \
    "Pokaż wyniki i rankingi" \
    "Usuń wyniki" \
  )

  case $choice in
    "Test GPU")
      OPTIND=1
      set -- "-g"
      ;;
    "Test CPU")
      OPTIND=1
      set -- "-c"
      ;;
    "Informacje o systemie")
      OPTIND=1
      set -- "-i"
      ;;
    "Pokaż wyniki i rankingi")
      OPTIND=1
      set -- "-p"
      ;;
    "Usuń wyniki")
      OPTIND=1
      set -- "-d"
      ;;
    *)
      exit 0
      ;;
  esac

  while getopts "$OPCJE" opt; do
  process_options "$opt"
  done
fi
