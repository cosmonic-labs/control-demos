#!/bin/bash

############################# Commands #################################

function render() {
  DEMO=$1
  helm template -n example-ns -f  "${DEMO}/values.http-trigger.yaml" example-name charts/http-trigger
}

function install() {
  DEMO=$1
  helm install --create-namespace -n "${DEMO}" -f "${DEMO}/values.http-trigger.yaml" "${DEMO}" charts/http-trigger
}

function delete() {
  DEMO=$1
  helm delete -n "${DEMO}" --ignore-not-found --cascade foreground "${DEMO}"
}

######################### Helper functions #############################

normal=$(tput sgr0)
red=$(tput setaf 1)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
blue=$(tput setaf 4)

function info() {
  echo "${blue}[INFO] $1${normal}"
}

function warn() {
  echo "${yellow}[WARN] $1${normal}"
}

function error() {
  echo "${red}[ERROR] $1${normal}"
}

success() {
  echo "${green}[SUCCESS] $1${normal}"
}

function demo_exists() {
  if [[ -d $1 ]]; then
    if [[ -f "$1/values.http-trigger.yaml" ]]; then
      return 0
    fi
  fi
  return 1
}

function is_make() {
  if [[ -n "${MAKELEVEL}" ]]; then
    return 0
  fi
  return 1
}

function list_demos() {
  for dir in ./*; do
    dir="${dir%/}" # Remove trailing slash
    if demo_exists "${dir}"; then
      echo "${dir#./}"
    fi
  done
}

function print_usage() {
  demos_available=$(list_demos)
  first_demo=$(list_demos | head -n 1)
  usage="Usage: ${0} {command} [{demo}]
  i.e. ${green}${0} install${normal} or ${green}${0} delete ${first_demo}${normal}"
  pre_cmd=""
  if is_make; then
    pre_cmd="helm-";
    usage="Usage: make {command}[-{demo}]
  i.e. ${green}make helm-install${normal} or ${green}make helm-delete-${first_demo}${normal}"
  fi

  cat <<EOF
${usage}

${blue}Commands:${normal}
  ${green}${pre_cmd}install${normal}       Install the Helm chart for the specified demo
  ${green}${pre_cmd}delete${normal}        Delete the Helm release for the specified demo
  ${green}${pre_cmd}render${normal}        Render the Helm chart template for the specified demo

${blue}Available demos:${green}
$(for demo in ${demos_available}; do
  echo "  ${demo}"
done)
${normal}
EOF
}

######################## Main script logic #############################

COMMAND=$1
DEMO_NAMES=("${@:2}")

if [[ -z ${COMMAND} ]]; then
  print_usage
  exit 1
fi

# If no specific demo names provided, process all demos
if [[ ${#DEMO_NAMES} -le 1 ]]; then
  info "No specific demo names provided, processing all demos."
  DEMO_NAMES=()
  for dir in */; do
    dir="${dir%/}" # Remove trailing slash
    if [[ -f "${dir}/values.http-trigger.yaml" ]]; then
      DEMO_NAMES+=("${dir}")
    fi
  done
fi

for DEMO in "${DEMO_NAMES[@]}"; do
  if ! demo_exists "${DEMO}"; then
    warn "Demo '${DEMO}' does not exist. Skipping."
    continue
  fi

  case "${COMMAND}" in
    install)
      install "${DEMO}"
      ;;
    delete)
      delete "${DEMO}"
      ;;
    render)
      render "${DEMO}"
      ;;
    *)
      error "Unknown command: ${COMMAND}"
      print_usage
      exit 1
      ;;
  esac

  success "Completed '${COMMAND}' for demo '${DEMO}'."
done

success "All operations completed."