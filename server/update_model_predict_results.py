import mysql.connector
import os
from utils.model import model_predict

dataBase = mysql.connector.connect(
    host=os.environ.get("WATEROIL_DB_HOST", "localhost"),
    user=os.environ.get("WATEROIL_DB_USER", "waterOil"),
    passwd=os.environ.get("WATEROIL_DB_PASSWORD", ""),
    database=os.environ.get("WATEROIL_DB_NAME", "waterOil"),
)

fetchCursor = dataBase.cursor()
updateCursor = dataBase.cursor()

fetchCursor.execute("SELECT id, path FROM photos")

for photo in fetchCursor.fetchall():
    result = model_predict(photo[1])
    updateCursor.execute("UPDATE photos SET result = " + str(result) + " WHERE id = " + str(photo[0]))
    dataBase.commit()

dataBase.close()