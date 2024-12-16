from flask import Flask, jsonify, request, render_template
from ai import AI_Agent, Environment
import threading
import time

app = Flask(__name__, static_url_path='/static', static_folder='static', template_folder='templates')

# Initialize environment and AI agent
env = Environment(grid_size=10, food_position=[5, 5], walls=[[3, 3], [4, 4]])
agent = AI_Agent(env)

# Lock for thread-safe operations
lock = threading.Lock()

# Control variables
training = True  # Flag to control training loop
epochs = 0
randomize_interval = 100  # Randomize environment every 100 epochs

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/reset', methods=['POST'])
def reset_env():
    global epochs
    with lock:
        env.reset()
        agent.reset()
        epochs = 0
        state = env.get_state()
    return jsonify(state)

@app.route('/step', methods=['POST'])
def step():
    # Not used in autonomous mode, but kept for potential manual control
    data = request.get_json()
    action = data.get('action')
    with lock:
        reward = agent.take_action(action)
        state = env.get_state()
    return jsonify({"reward": reward, "state": state})

@app.route('/state', methods=['GET'])
def get_state():
    with lock:
        state = env.get_state()
        current_epoch = epochs
    return jsonify({"state": state, "epoch": current_epoch})

def training_loop():
    global epochs
    while training:
        with lock:
            action = agent.choose_action()
            reward = agent.take_action(action)
            epochs += 1
            state = env.get_state()
            state['reward'] = reward
            # After 100 epochs, randomize the environment
            if epochs % randomize_interval == 0:
                env.randomize_environment()
                agent.reset()
                print(f"Environment randomized at epoch {epochs}")
        time.sleep(0.1)  # Delay to simulate time between actions

if __name__ == "__main__":
    # Start training loop in a separate thread
    training_thread = threading.Thread(target=training_loop)
    training_thread.daemon = True
    training_thread.start()
    # Run Flask app
    app.run(debug=True)
