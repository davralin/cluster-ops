#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_dir}"' EXIT

latest_github_release() {
  basename "$(curl -fsSLI -o /dev/null -w '%{url_effective}' "$1/releases/latest")"
}

update_operator() {
  local name="$1"
  local release="$2"
  local url="$3"
  local target="$4"
  local manifest="${tmp_dir}/${name}.yaml"
  local rendered="${tmp_dir}/$(basename "${target}")"
  local found_resources=false
  local line=""

  curl -fsSL "${url}" -o "${manifest}"
  grep -q '^kind: CustomResourceDefinition$' "${manifest}"

  while IFS= read -r line || [[ -n "${line}" ]]; do
    printf '%s\n' "${line}" >>"${rendered}"
    if [[ "${line}" =~ ^[[:space:]]{4}resources:[[:space:]]*$ ]]; then
      found_resources=true
      break
    fi
  done <"${target}"

  [[ "${found_resources}" == true ]]

  printf '      - |\n' >>"${rendered}"
  while IFS= read -r line || [[ -n "${line}" ]]; do
    if [[ -n "${line}" ]]; then
      printf '        %s\n' "${line}" >>"${rendered}"
    else
      printf '\n' >>"${rendered}"
    fi
  done <"${manifest}"

  mv "${rendered}" "${target}"
  printf 'Updated %s raw resources to %s\n' "${name}" "${release}"
}

kubevirt_release="$(curl -fsSL https://storage.googleapis.com/kubevirt-prow/release/kubevirt/kubevirt/stable.txt)"
cdi_release="$(latest_github_release https://github.com/kubevirt/containerized-data-importer)"

update_operator \
  kubevirt-operator \
  "${kubevirt_release}" \
  "https://github.com/kubevirt/kubevirt/releases/download/${kubevirt_release}/kubevirt-operator.yaml" \
  "${script_dir}/helm-release-kubevirt-operator.yaml"

update_operator \
  cdi-operator \
  "${cdi_release}" \
  "https://github.com/kubevirt/containerized-data-importer/releases/download/${cdi_release}/cdi-operator.yaml" \
  "${script_dir}/helm-release-cdi-operator.yaml"
