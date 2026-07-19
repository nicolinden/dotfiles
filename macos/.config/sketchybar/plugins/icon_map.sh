#!/usr/bin/env bash

icon_for_app() {
  case "$1" in
    "Safari")
      echo ":safari:"
      ;;
    "Google Chrome")
      echo ":google_chrome:"
      ;;
    "Code")
      echo ":code:"
      ;;
    "WezTerm")
      echo ":wezterm:"
      ;;
    "Terminal")
      echo ":terminal:"
      ;;
    "ForkLift")
      echo ":forklift:"
      ;;
    *"WhatsApp"*)
      echo ":whatsapp:"
      ;;
    "Messages")
      echo ":messages:"
      ;;
    "ChatGPT")
        echo ":chatgpt_atlas:"
      ;;
    "Finder")
      echo ":finder:"
      ;;
    "System Settings")
      echo ":system_settings:"
      ;;
    *)
      echo ":default:"
      ;;
  esac
}
