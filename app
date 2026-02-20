from fastapi import FastAPI, HTTPException, UploadFile, File
from pydantic import BaseModel
import boto3
import traceback

app = FastAPI()


REGION = "ap-south-1"
TABLE_NAME = "todo-items"
BUCKET_NAME = "fastapi-todo-bucket-721366939828"   # <-- change this

# DynamoDB connection
dynamodb = boto3.resource("dynamodb", region_name=REGION)
table = dynamodb.Table(TABLE_NAME)

# S3 connection
s3 = boto3.client("s3", region_name=REGION)


class Todo(BaseModel):
    id: str
    title: str
    description: str



@app.post("/todos")
def create_todo(todo: Todo):
    try:
        table.put_item(
            Item={
                "id": todo.id,
                "title": todo.title,
                "description": todo.description,
                "completed": False
            },
            ConditionExpression="attribute_not_exists(id)"  # Prevent duplicate ID
        )

        return {"message": "Todo created successfully", "id": todo.id}

    except Exception as e:
        return {
            "error": str(e),
            "trace": traceback.format_exc()
        }


@app.get("/todos/{todo_id}")
def get_todo(todo_id: str):
    try:
        response = table.get_item(Key={"id": todo_id})

        if "Item" not in response:
            raise HTTPException(status_code=404, detail="Todo not found")

        return response["Item"]

    except Exception as e:
        return {
            "error": str(e),
            "trace": traceback.format_exc()
        }



@app.delete("/todos/{todo_id}")
def delete_todo(todo_id: str):
    try:
        table.delete_item(Key={"id": todo_id})
        return {"message": "Todo deleted successfully"}

    except Exception as e:
        return {
            "error": str(e),
            "trace": traceback.format_exc()
        }


# -----------------------------
# UPLOAD FILE TO S3
# -----------------------------
@app.post("/upload")
def upload_file(file: UploadFile = File(...)):
    try:
        file_key = file.filename

        s3.upload_fileobj(file.file, BUCKET_NAME, file_key)

        file_url = f"https://{BUCKET_NAME}.s3.{REGION}.amazonaws.com/{file_key}"

        return {
            "message": "File uploaded successfully",
            "file_url": file_url
        }

    except Exception as e:
        return {
            "error": str(e),
            "trace": traceback.format_exc()
        }
