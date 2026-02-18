#! /bin/bash

# Create archive or exit if the command fails
set -eu

# validate subscription status
API_URL="https://agent.api.stepsecurity.io/v1/github/$GITHUB_REPOSITORY/actions/subscription"

# Set a timeout for the curl command (3 seconds)
RESPONSE=$(curl --max-time 3 -s -w "%{http_code}" "$API_URL" -o /dev/null) || true
CURL_EXIT_CODE=$?

# Decide based on curl exit code and HTTP status
if [ "$CURL_EXIT_CODE" -ne 0 ]; then
  echo "Timeout or API not reachable. Continuing to next step."
elif [ "$RESPONSE" = "200" ]; then
  :
elif [ "$RESPONSE" = "403" ]; then
  echo "Subscription is not valid. Reach out to support@stepsecurity.io"
  exit 1
else
  echo "Timeout or API not reachable. Continuing to next step."
fi

printf "\n📦 Creating %s archive...\n" "$INPUT_TYPE"

if [ -n "$INPUT_COMMAND" ]
then
  bash -c "$INPUT_COMMAND"
fi

if [ "$INPUT_DIRECTORY" != "." ]
then
  cd "$INPUT_DIRECTORY"
fi

read -ra PATH_ARGS <<< "$INPUT_PATH"
read -ra CUSTOM_ARGS <<< "$INPUT_CUSTOM"
read -ra EXCLUSION_ARGS <<< "$INPUT_EXCLUSIONS"
read -ra RECURSIVE_EXCLUSION_ARGS <<< "$INPUT_RECURSIVE_EXCLUSIONS"

if [ "$INPUT_TYPE" = "zip" ]
then
  if [ "$RUNNER_OS" = "Windows" ]
  then
    if [ -z "$INPUT_EXCLUSIONS" ]
    then
      7z a -tzip "$INPUT_FILENAME" "${PATH_ARGS[@]}" "${CUSTOM_ARGS[@]}" || { printf "\n⛔ Unable to create %s archive.\n" "$INPUT_TYPE"; exit 1;  }
    else
      EXCLUSIONS=()

      for EXCLUSION in "${EXCLUSION_ARGS[@]}"
      do
        EXCLUSIONS+=("-x!${EXCLUSION}")
      done

      for EXCLUSION in "${RECURSIVE_EXCLUSION_ARGS[@]}"
      do
        EXCLUSIONS+=("-xr!${EXCLUSION}")
      done

      7z a -tzip "$INPUT_FILENAME" "${PATH_ARGS[@]}" "${EXCLUSIONS[@]}" "${CUSTOM_ARGS[@]}" || { printf "\n⛔ Unable to create %s archive.\n" "$INPUT_TYPE"; exit 1;  }
    fi
  else
    if [ -z "$INPUT_EXCLUSIONS" ]
    then
      zip -r "$INPUT_FILENAME" "${PATH_ARGS[@]}" "${CUSTOM_ARGS[@]}" || { printf "\n⛔ Unable to create %s archive.\n" "$INPUT_TYPE"; exit 1;  }
    else
      zip -r "$INPUT_FILENAME" "${PATH_ARGS[@]}" -x "${EXCLUSION_ARGS[@]}" "${CUSTOM_ARGS[@]}" || { printf "\n⛔ Unable to create %s archive.\n" "$INPUT_TYPE"; exit 1;  }
    fi
  fi
elif [ "$INPUT_TYPE" = "7z" ] || [ "$INPUT_TYPE" = "7zip" ]
then
  if [ -z "$INPUT_EXCLUSIONS" ]
  then
    7z a -tzip "$INPUT_FILENAME" "${PATH_ARGS[@]}" "${CUSTOM_ARGS[@]}" || { printf "\n⛔ Unable to create %s archive.\n" "$INPUT_TYPE"; exit 1;  }
  else
    EXCLUSIONS=()

    for EXCLUSION in "${EXCLUSION_ARGS[@]}"
    do
      EXCLUSIONS+=("-x!${EXCLUSION}")
    done

    for EXCLUSION in "${RECURSIVE_EXCLUSION_ARGS[@]}"
    do
      EXCLUSIONS+=("-xr!${EXCLUSION}")
    done

    7z a -tzip "$INPUT_FILENAME" "${PATH_ARGS[@]}" "${EXCLUSIONS[@]}" "${CUSTOM_ARGS[@]}" || { printf "\n⛔ Unable to create %s archive.\n" "$INPUT_TYPE"; exit 1;  }
  fi
elif [ "$INPUT_TYPE" = "tar" ] || [ "$INPUT_TYPE" = "tar.gz" ]
then
  if [ -z "$INPUT_EXCLUSIONS" ]
  then
    tar -zcvf "$INPUT_FILENAME" "${PATH_ARGS[@]}" "${CUSTOM_ARGS[@]}" || { printf "\n⛔ Unable to create %s archive.\n" "$INPUT_TYPE"; exit 1;  }
  else
    EXCLUSIONS=()

    for EXCLUSION in "${EXCLUSION_ARGS[@]}"
    do
      EXCLUSIONS+=("--exclude=${EXCLUSION}")
    done

    tar "${EXCLUSIONS[@]}" -zcvf "$INPUT_FILENAME" "${PATH_ARGS[@]}" "${CUSTOM_ARGS[@]}" || { printf "\n⛔ Unable to create %s archive.\n" "$INPUT_TYPE"; exit 1;  }
  fi
else
  printf "\n⛔ Invalid archiving tool.\n"; exit 1;
fi

printf "\n✔ Successfully created %s archive.\n" "$INPUT_TYPE"
