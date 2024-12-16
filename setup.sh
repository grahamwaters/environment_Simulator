#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

# Define project directory
PROJECT_DIR="ai-agent-simulation-2d"

# Create project directory and navigate into it
mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

# Create subdirectories
mkdir -p static templates

# Create requirements.txt
cat > requirements.txt <<EOF
Flask==2.2.5
numpy==1.23.5
EOF

# Create .gitignore
cat > .gitignore <<EOF
venv/
__pycache__/
*.pyc
*.pyo
*.log
.DS_Store
EOF

# Create README.md
cat > README.md <<EOF
# AI Agent Simulation (2D)

This project demonstrates a simple reinforcement learning (Q-learning) agent navigating a 2D grid environment. The environment and AI logic run on a Flask backend, while the frontend is built with HTML, CSS, and JavaScript.

## Features
- **2D Grid Environment**: A 10x10 grid representing the simulation space.
- **AI Agent**: A blue square that learns to navigate towards the food.
- **Food**: A green square that the agent aims to reach.
- **Walls**: Gray squares that the agent must avoid.
- **Autonomous Movement**: The agent moves on its own based on learned policies.
- **Environment Randomization**: The environment randomizes every 100 epochs to introduce variability.
- **Real-time Visualization**: The grid updates dynamically to reflect the agent's actions and environment changes.

## Setup and Run

1. **Run the setup script:**
   \`\`\`
   ./setup.sh
   \`\`\`

2. **Activate the virtual environment:**
   \`\`\`
   source venv/bin/activate
   \`\`\`

3. **Run the Flask server:**
   \`\`\`
   python app.py
   \`\`\`

4. **Open [http://localhost:5000](http://localhost:5000) in your web browser.**

## Future Enhancements
- Implement more advanced AI algorithms.
- Introduce multiple agents.
- Add dynamic obstacles.
- Persist the AI's learning across sessions.
- Provide user controls to adjust AI parameters.

## License
MIT License
EOF

# Create virtual environment
python3 -m venv venv

# Activate virtual environment
source venv/bin/activate

# Upgrade pip
pip install --upgrade pip

# Install dependencies
pip install -r requirements.txt

# Create app.py
cat > app.py <<EOF
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
    return jsonify(state)

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
EOF

# Create ai.py
cat > ai.py <<EOF
import numpy as np
import random

class Environment:
    def __init__(self, grid_size=10, food_position=[5,5], walls=[[3,3],[4,4]]):
        self.grid_size = grid_size
        self.initial_agent_position = [0, 0]
        self.agent_position = self.initial_agent_position.copy()
        self.food_position = food_position
        self.walls = walls

    def reset(self):
        self.agent_position = self.initial_agent_position.copy()
        # Optionally, respawn food at random:
        # self.food_position = self.random_food_position()

    def get_state(self):
        return {
            "agent_position": self.agent_position,
            "food_position": self.food_position,
            "walls": self.walls,
            "reward": 0
        }

    def is_collision(self, position):
        if position in self.walls:
            return True
        x, y = position
        if x < 0 or x >= self.grid_size or y < 0 or y >= self.grid_size:
            return True
        return False

    def move_agent(self, action):
        x, y = self.agent_position
        if action == "up":
            y -= 1
        elif action == "down":
            y += 1
        elif action == "left":
            x -= 1
        elif action == "right":
            x += 1
        new_position = [x, y]
        if not self.is_collision(new_position):
            self.agent_position = new_position
            return True
        else:
            return False

    def check_food(self):
        return self.agent_position == self.food_position

    def random_food_position(self):
        while True:
            pos = [random.randint(0, self.grid_size -1), random.randint(0, self.grid_size -1)]
            if pos != self.agent_position and pos not in self.walls:
                return pos

    def randomize_environment(self):
        # Randomize food position
        self.food_position = self.random_food_position()
        # Randomize walls: for simplicity, we'll randomly place 2 walls
        self.walls = []
        while len(self.walls) < 2:
            pos = [random.randint(0, self.grid_size -1), random.randint(0, self.grid_size -1)]
            if pos != self.agent_position and pos != self.food_position and pos not in self.walls:
                self.walls.append(pos)

class AI_Agent:
    def __init__(self, environment, alpha=0.1, gamma=0.9, epsilon=0.2):
        self.env = environment
        self.alpha = alpha  # Learning rate
        self.gamma = gamma  # Discount factor
        self.epsilon = epsilon  # Exploration rate
        self.actions = ["up", "down", "left", "right"]
        self.q_table = {}

    def get_state_key(self):
        # Simplistic state representation: agent position
        return tuple(self.env.agent_position)

    def choose_action(self):
        state = self.get_state_key()
        if state not in self.q_table:
            self.q_table[state] = {action: 0.0 for action in self.actions}

        if random.uniform(0,1) < self.epsilon:
            action = random.choice(self.actions)
        else:
            max_value = max(self.q_table[state].values())
            actions_with_max = [action for action, value in self.q_table[state].items() if value == max_value]
            action = random.choice(actions_with_max)
        return action

    def take_action(self, action):
        prev_state = self.get_state_key()
        moved = self.env.move_agent(action)
        if not moved:
            reward = -1  # Penalty for hitting a wall
        else:
            if self.env.check_food():
                reward = 10  # Reward for reaching food
                self.env.reset()
            else:
                reward = -0.1  # Small penalty to encourage shorter paths

        new_state = self.get_state_key()
        self.update_q_table(prev_state, action, reward, new_state)
        return reward

    def update_q_table(self, state, action, reward, new_state):
        if state not in self.q_table:
            self.q_table[state] = {a:0.0 for a in self.actions}
        if new_state not in self.q_table:
            self.q_table[new_state] = {a:0.0 for a in self.actions}

        old_value = self.q_table[state][action]
        next_max = max(self.q_table[new_state].values())
        new_value = old_value + self.alpha * (reward + self.gamma * next_max - old_value)
        self.q_table[state][action] = new_value

    def reset(self):
        # Optionally adjust epsilon to reduce exploration over time
        if self.epsilon > 0.01:
            self.epsilon *= 0.99  # Decay exploration rate
EOF

# Create templates/index.html
cat > templates/index.html <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>AI Agent Simulation (2D)</title>
    <link rel="stylesheet" href="/static/styles.css">
</head>
<body>
    <h1>AI Agent Simulation (2D)</h1>
    <p>The AI agent is learning to navigate the grid autonomously.</p>
    <button id="reset-button">Reset Environment</button>
    <div id="grid"></div>
    <p>Epoch: <span id="epoch">0</span></p>
    <p>Reward: <span id="reward">0</span></p>
    <script src="/static/script.js"></script>
</body>
</html>
EOF

# Create static/styles.css
cat > static/styles.css <<EOF
body {
    font-family: Arial, sans-serif;
    text-align: center;
    background-color: #f0f0f0;
    margin: 0;
    padding: 20px;
}

h1 {
    margin-bottom: 10px;
}

#grid {
    display: grid;
    grid-template-columns: repeat(10, 40px);
    grid-template-rows: repeat(10, 40px);
    gap: 2px;
    justify-content: center;
    margin: 20px auto;
}

.cell {
    width: 40px;
    height: 40px;
    background-color: #ffffff;
    border: 1px solid #cccccc;
    box-sizing: border-box;
    position: relative;
}

.agent {
    background-color: #0000ff;
    width: 100%;
    height: 100%;
}

.food {
    background-color: #00ff00;
    width: 100%;
    height: 100%;
}

.wall {
    background-color: #555555;
    width: 100%;
    height: 100%;
}

button {
    padding: 10px 20px;
    font-size: 16px;
    cursor: pointer;
}

p {
    font-size: 18px;
}
EOF

# Create static/script.js
cat > static/script.js <<'EOF'
const gridElement = document.getElementById("grid");
const resetButton = document.getElementById("reset-button");
const rewardElement = document.getElementById("reward");
const epochElement = document.getElementById("epoch");
const gridSize = 10;

// Render the grid based on state
function renderGrid(state) {
    gridElement.innerHTML = "";
    for (let y = 0; y < gridSize; y++) {
        for (let x = 0; x < gridSize; x++) {
            const cell = document.createElement("div");
            cell.classList.add("cell");
            // Check for walls
            state.walls.forEach(wall => {
                if (wall[0] === x && wall[1] === y) {
                    cell.classList.add("wall");
                }
            });
            // Check for food
            if (state.food_position[0] === x && state.food_position[1] === y) {
                cell.classList.add("food");
            }
            // Check for agent
            if (state.agent_position[0] === x && state.agent_position[1] === y) {
                cell.classList.add("agent");
            }
            gridElement.appendChild(cell);
        }
    }
    // Update reward display
    rewardElement.textContent = state.reward;
}

// Fetch initial state
async function initialize() {
    try {
        const response = await fetch("/reset", { method: "POST" });
        const data = await response.json();
        renderGrid(data);
        epochElement.textContent = "0";
    } catch (error) {
        console.error("Error initializing simulation:", error);
    }
}

// Handle reset button
resetButton.addEventListener("click", initialize);

// Fetch and render state periodically
let currentEpoch = 0;
setInterval(async () => {
    try {
        const stateResponse = await fetch("/state");
        const stateData = await stateResponse.json();
        renderGrid(stateData);
        epochElement.textContent = currentEpoch;
    } catch (error) {
        console.error("Error fetching state:", error);
    }
}, 500); // Update every 500ms

// Initialize on page load
window.onload = initialize;
EOF

# Make setup.sh executable
# chmod +x setup.sh

# Provide instructions to the user
echo "Setup complete!
To run the project, follow these steps:

1. Navigate to the project directory:
   \`\`\`
   cd $PROJECT_DIR
   \`\`\`

2. Activate the virtual environment:
   \`\`\`
   source venv/bin/activate
   \`\`\`

3. Run the Flask server:
   \`\`\`
   python app.py
   \`\`\`

4. Open your web browser and go to [http://localhost:5000](http://localhost:5000).

The AI agent will start moving autonomously based on its learned policies. The environment will randomize every 100 epochs, introducing new challenges for the agent.

If you encounter any issues, please check the browser console for errors and ensure that all dependencies are correctly installed.
"

# Make setup.sh executable
# chmod +x ./setup.sh
# cd ai-agent-simulation-2d

echo "Project setup script created successfully."
source venv/bin/activate
python app.py