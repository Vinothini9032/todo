from fastapi import FastAPI, HTTPException, UploadFile, File
from pydantic import BaseModel
import boto3
import traceback

app = FastAPI()

REGION = "ap-south-1"
TABLE_NAME = "todo-items"
BUCKET_NAME = "vinothini-todo-bucket-721366939828-ap-south-1"

# DynamoDB
dynamodb = boto3.resource("dynamodb", region_name=REGION)
table = dynamodb.Table(TABLE_NAME)

# S3
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
            }
        )
        return {"message": "Todo created", "id": todo.id}
    except Exception as e:
        return {"error": str(e), "trace": traceback.format_exc()}


@app.get("/todos/{todo_id}")
def get_todo(todo_id: str):
    try:
        response = table.get_item(Key={"id": todo_id})
        if "Item" not in response:
            raise HTTPException(status_code=404, detail="Not found")
        return response["Item"]
    except Exception as e:
        return {"error": str(e), "trace": traceback.format_exc()}


@app.delete("/todos/{todo_id}")
def delete_todo(todo_id: str):
    try:
        table.delete_item(Key={"id": todo_id})
        return {"message": "Todo deleted"}
    except Exception as e:
        return {"error": str(e), "trace": traceback.format_exc()}


@app.post("/upload")
def upload_file(file: UploadFile = File(...)):
    try:
        key = file.filename
        s3.upload_fileobj(file.file, BUCKET_NAME, key)
        return {
            "message": "Uploaded",
            "file_url": f"https://{BUCKET_NAME}.s3.{REGION}.amazonaws.com/{key}"
        }
    except Exception as e:
        return {"error": str(e), "trace": traceback.format_exc()}
