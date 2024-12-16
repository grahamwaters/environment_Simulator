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

class AI_Agent:
    def __init__(self, environment, alpha=0.1, gamma=0.9, epsilon=0.2):
        self.env = environment
        self.alpha = alpha
        self.gamma = gamma
        self.epsilon = epsilon
        self.actions = ["up", "down", "left", "right"]
        self.q_table = {}

    def get_state_key(self):
        return tuple(self.env.agent_position)

    def choose_action(self):
        state = self.get_state_key()
        if state not in self.q_table:
            self.q_table[state] = {action: 0.0 for action in self.actions}

        if random.uniform(0,1) < self.epsilon:
            action = random.choice(self.actions)
        else:
            max_value = max(self.q_table[state].values())
            actions_with_max = [a for a, v in self.q_table[state].items() if v == max_value]
            action = random.choice(actions_with_max)
        return action

    def take_action(self, action):
        prev_state = self.get_state_key()
        moved = self.env.move_agent(action)
        if not moved:
            reward = -1
        else:
            if self.env.check_food():
                reward = 10
                self.env.reset()
            else:
                reward = -0.1

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
