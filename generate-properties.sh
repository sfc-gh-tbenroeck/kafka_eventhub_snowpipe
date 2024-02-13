#!/bin/bash

# Substitutes environment variables into the template files
generate_properties_from_template() {
  local template_file=$1
  local property_file=$2

  # Use envsubst to substitute environment variable values into the template
  envsubst < "${template_file}" > "${property_file}"
}

# Overrides or appends properties based on prefixed environment variables
override_or_append_properties() {
  local property_file=$1
  local prefix=$2

  # Iterate over all environment variables
  while IFS= read -r line; do
    # Extract name and value from the environment variable
    local name=$(echo "$line" | cut -d= -f1)
    local value=$(echo "$line" | sed -e "s/^$name=//")

    # Check if the variable starts with the prefix
    if [[ $name == ${prefix}* ]]; then
      local prop_name=${name#$prefix}

      # Check if the property already exists in the file
      if grep -q "^${prop_name}=" "${property_file}"; then
        # Property exists, replace it
        sed -i "s|^${prop_name}=.*|${prop_name}=${value}|g" "${property_file}"
      else
        # Property does not exist, append it
        echo "${prop_name}=${value}" >> "${property_file}"
      fi
    fi
  done < <(env | grep "^${prefix}")
}

# Generate properties from templates using envsubst
generate_properties_from_template "/opt/kafka/config/kafka_eventhub.properties.template" "/opt/kafka/config/kafka_eventhub.properties"
generate_properties_from_template "/opt/kafka/config/kafka_snowflake_snowpipe.properties.template" "/opt/kafka/config/kafka_snowflake_snowpipe.properties"

# Override or append additional properties based on prefixed environment variables
override_or_append_properties "/opt/kafka/config/kafka_eventhub.properties" "kafka_eventhub_"
override_or_append_properties "/opt/kafka/config/kafka_snowflake_snowpipe.properties" "kafka_snowflake_"

# Continue with Kafka Connect startup
exec "$@"
