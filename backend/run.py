from app import create_app, db
from app.models import *

app = create_app()

@app.route('/')
def index():
    return {'message': 'Medical App API', 'status': 'running'}

@app.cli.command()
def init_db():
    """Initialize the database."""
    db.create_all()
    print('Database initialized!')

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5001)
