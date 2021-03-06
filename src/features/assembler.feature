Feature: Ensuring a short read assembler matches the bioboxes specification

  Scenario: An empty biobox.yaml file
    Given an empty file named "input/biobox.yaml"
    When I run the bash command:
      """
      docker run \
        --volume="$(pwd)/input:/bbx/input" \
        ${IMAGE} \
        ${TASK}
      """
    Then the exit status should be 1
     And the stderr should contain:
      """
      None is not of type 'object'\n
      """

  Scenario: A garbled biobox.yaml file.
    Given a file named "input/biobox.yaml" with:
      """
      'nonsense"/4*
      """
    When I run the bash command:
      """
      docker run \
        --volume="$(pwd)/input:/bbx/input" \
        ${IMAGE} \
        ${TASK}
      """
    Then the exit status should be 1
     And the stderr should contain:
      """
      Error parsing the YAML file: /bbx/input/biobox.yaml\n
      """

  Scenario: An biobox.yaml missing the version number.
    Given a file named "input/biobox.yaml" with:
      """
      arguments:
        - fasta:
          - id: "pe"
            value: "/reads.fasta"
            type: contigs
      """
    When I run the bash command:
      """
      docker run --volume="$(pwd)/input:/bbx/input" ${IMAGE} ${TASK}
      """
    Then the exit status should be 1
     And the stderr should contain:
      """
      'version' is a required property\n
      """

  Scenario: An biobox.yaml with a missing patch version number.
    Given a file named "input/biobox.yaml" with:
      """
      version: "0.9"
      arguments:
        - fasta:
          - id: "pe"
            value: "/reads.fasta"
            type: contigs
      """
    When I run the bash command:
      """
      docker run \
        --env="TASK=default" \
        --volume="$(pwd)/input:/bbx/input:ro" \
        ${IMAGE} \
        ${TASK}
      """
    Then the exit status should be 1
     And the stderr should contain:
      """
      '0.9' does not match '^0.9.\\d+$'\n
      """

  Scenario: An biobox.yaml with a wrong version number.
    Given a file named "input/biobox.yaml" with:
      """
      version: "0.8.0"
      arguments:
        - fasta:
          - id: "pe"
            value: "/reads.fasta"
            type: contigs
     """
    When I run the bash command:
      """
      docker run \
        --env="TASK=default" \
        --volume="$(pwd)/input:/bbx/input:ro" \
        ${IMAGE} ${TASK}
      """
    Then the exit status should be 1
     And the stderr should contain:
      """
      '0.8.0' does not match '^0.9.\\d+$'\n
      """

  Scenario: An biobox.yaml with a missing arguments field.
    Given a file named "input/biobox.yaml" with:
      """
      version: "0.9.0"
      """
    When I run the bash command:
      """
      docker run \
        --env="TASK=default" \
        --volume="$(pwd)/input:/bbx/input" \
        ${IMAGE} ${TASK}
      """
    Then the exit status should be 1
     And the stderr should contain:
      """
      'arguments' is a required property\n
      """

  Scenario Outline: An biobox.yaml with an additional unknown field
    Given a file named "input/biobox.yaml" with:
      """
      version: "0.9.0"
      arguments:
        - fasta:
          - id: "pe"
            value: "/reads.fasta"
            type: contigs
      <field>: {}
      """
    When I run the bash command:
      """
      docker run \
        --env="TASK=default" \
        --volume="$(pwd)/input:/bbx/input:ro" \
        ${IMAGE} ${TASK}
      """
    Then the exit status should be 1
     And the stderr should contain:
      """
      Additional properties are not allowed ('<field>' was unexpected)\n
      """

    Examples:
      | field         |
      | unknown       |
      | invalid_fasta |


  Scenario: Run assembler with basic input
    Given a directory named "output"
    And a directory named "input"
    And I successfully run `cp -r ../../reference input`
    And I successfully run `cp ../../assembly.fasta input`
    And a file named "input/biobox.yaml" with:
      """
      ---
      version: 0.9.0
      arguments:
        - fasta:
          - id: "1"
            value: "/bbx/input/assembly.fasta"
            type: contigs
        - fasta_dir: "/bbx/input/reference"
      """
    When I run the bash command:
      """
      docker run \
        --volume="$(pwd)/input:/bbx/input:ro" \
        --volume="$(pwd)/output:/bbx/output:rw" \
        ${IMAGE} ${TASK}
      """
    Then the exit status should be 0
    And a file named "output/biobox.yaml" should exist

  Scenario: Check if output log is produced.
    Given a directory named "output"
    And a directory named "input"
    And a directory named "metadata"
    And I successfully run `cp -r ../../reference input`
    And I successfully run `cp ../../assembly.fasta input`
    And a file named "input/biobox.yaml" with:
    """
    ---
    version: 0.9.0
    arguments:
      - fasta:
        - id: "1"
          value: "/bbx/input/assembly.fasta"
          type: contigs
      - fasta_dir: "/bbx/input/reference"
    """
    When I run the bash command:
    """
      docker run \
        --volume="$(pwd)/metadata:/bbx/metadata:rw" \
        --volume="$(pwd)/input:/bbx/input:ro" \
        --volume="$(pwd)/output:/bbx/output:rw" \
        ${IMAGE} ${TASK}
      """
    Then the exit status should be 0
    And a file named "metadata/log.txt" should exist