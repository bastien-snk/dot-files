hmc() {
  local hmc_root="${XDG_DATA_HOME:-$HOME/.local/share}/headlessmc"
  local hmc_dir="${hmc_root}/HeadlessMC"
  local config_file="${hmc_dir}/config.properties"
  local java_root="$HOME/.local/share/mise/installs/java"
  local headlessmc_java="$hmc_root/runtime/headlessmc.jdk/Contents/Home/bin/java"
  local -a java_versions=()
  local java_prop tmp_file

  [[ -x "${headlessmc_java}" ]] && java_versions+=("${headlessmc_java}")
  [[ -x "${java_root}/21/bin/java" ]] && java_versions+=("${java_root}/21/bin/java")
  [[ -x "${java_root}/corretto-8/bin/java" ]] && java_versions+=("${java_root}/corretto-8/bin/java")

  mkdir -p "${hmc_dir}"
  java_prop="hmc.java.versions=${(j:;:)java_versions}"

  if [[ -f "${config_file}" ]]; then
    tmp_file="${config_file}.tmp.$$"
    awk -v java_prop="$java_prop" '
      BEGIN { replaced = 0 }
      /^hmc\.java\.versions=/ {
        print java_prop
        replaced = 1
        next
      }
      { print }
      END {
        if (!replaced) {
          print java_prop
        }
      }
    ' "${config_file}" > "${tmp_file}" && mv "${tmp_file}" "${config_file}"
  else
    printf '%s\n' "$java_prop" > "${config_file}"
  fi

  (
    cd "${hmc_root}" || exit 1
    command headlessmc "$@"
  )
}
