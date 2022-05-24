import json
import jsonschema as JSD

def validate_json(json_data, schema_file):
    """
    Validates the resulting ct against a defined json schema, given a schema_file

    Arguments:
        json_data: The resulting CT pacakge to validate
        schema_file: Path to a schema file defining ct package schema
    """
    try:
        with open(schema_file) as f:
            schema = json.load(f)
        JSD.validate(json_data, schema=schema)
        return True
    except Exception as e:
        print(f"Error encountered while validating json schema: {e}")
        return False

jsonfile = "../json_out/adam/adae.json"
schemafile = "../schema/dataset.schema.json"
validate_json(json.load(open(jsonfile)), schemafile)

