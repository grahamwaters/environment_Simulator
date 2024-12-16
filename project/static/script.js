let scene, camera, renderer;
let agentMesh, foodMesh, wallMeshes = [];
let gridSize = 10;
let cellSize = 1;
let rewardElement = document.getElementById('reward');
let resetButton = document.getElementById('reset-button');

// Initialize 3D scene
function initScene() {
    scene = new THREE.Scene();
    camera = new THREE.PerspectiveCamera(45, window.innerWidth / (window.innerHeight*0.8), 0.1, 1000);
    camera.position.set(gridSize/2, gridSize*1.5, gridSize*2);
    camera.lookAt(new THREE.Vector3(gridSize/2,0,gridSize/2));

    renderer = new THREE.WebGLRenderer({antialias: true});
    renderer.setSize(window.innerWidth, window.innerHeight*0.8);
    document.getElementById('scene-container').appendChild(renderer.domElement);

    // Lights
    const ambientLight = new THREE.AmbientLight(0xffffff, 0.6);
    scene.add(ambientLight);

    const dirLight = new THREE.DirectionalLight(0xffffff, 0.8);
    dirLight.position.set(10, 20, 10);
    scene.add(dirLight);

    // Ground plane
    const planeGeom = new THREE.PlaneGeometry(gridSize*cellSize, gridSize*cellSize, gridSize, gridSize);
    const planeMat = new THREE.MeshPhongMaterial({color: 0x222222, side: THREE.DoubleSide});
    const plane = new THREE.Mesh(planeGeom, planeMat);
    plane.rotation.x = Math.PI / 2;
    scene.add(plane);
}

// Create geometry for agent, walls, food
function createAgent() {
    const agentGeom = new THREE.SphereGeometry(0.4, 16, 16);
    const agentMat = new THREE.MeshPhongMaterial({color: 0x0000ff});
    agentMesh = new THREE.Mesh(agentGeom, agentMat);
    scene.add(agentMesh);
}

function createFood() {
    const foodGeom = new THREE.BoxGeometry(0.4,0.4,0.4);
    const foodMat = new THREE.MeshPhongMaterial({color: 0x00ff00});
    foodMesh = new THREE.Mesh(foodGeom, foodMat);
    scene.add(foodMesh);
}

function createWalls(walls) {
    // Remove old walls
    for (let w of wallMeshes) {
        scene.remove(w);
    }
    wallMeshes = [];

    const wallGeom = new THREE.BoxGeometry(1,1,1);
    const wallMat = new THREE.MeshPhongMaterial({color: 0x555555});

    for (let w of walls) {
        let wallMesh = new THREE.Mesh(wallGeom, wallMat);
        // Position in scene
        wallMesh.position.set(w[0]*cellSize + 0.5, 0.5, w[1]*cellSize + 0.5);
        wallMeshes.push(wallMesh);
        scene.add(wallMesh);
    }
}

// Position objects
function positionAgent(x, y) {
    agentMesh.position.set(x*cellSize + 0.5, 0.5, y*cellSize + 0.5);
}

function positionFood(x, y) {
    foodMesh.position.set(x*cellSize + 0.5, 0.5, y*cellSize + 0.5);
}

function animate() {
    requestAnimationFrame(animate);
    renderer.render(scene, camera);
}

async function initialize() {
    const response = await fetch("/reset", { method: "POST" });
    const data = await response.json();
    createWalls(data.walls);
    positionAgent(data.agent_position[0], data.agent_position[1]);
    positionFood(data.food_position[0], data.food_position[1]);
    rewardElement.textContent = 0;
}

resetButton.addEventListener("click", initialize);

async function step(action) {
    const response = await fetch("/step", {
        method: "POST",
        headers: {"Content-Type": "application/json"},
        body: JSON.stringify({action: action})
    });
    const stepData = await response.json();
    const stateResponse = await fetch("/state");
    const stateData = await stateResponse.json();

    createWalls(stateData.walls);
    positionAgent(stateData.agent_position[0], stateData.agent_position[1]);
    positionFood(stateData.food_position[0], stateData.food_position[1]);
    rewardElement.textContent = stepData.reward;
}

document.addEventListener("keydown", (event) => {
    if (event.key === "ArrowUp") step("up");
    if (event.key === "ArrowDown") step("down");
    if (event.key === "ArrowLeft") step("left");
    if (event.key === "ArrowRight") step("right");
});

// Resize renderer on window resize
window.addEventListener('resize', () => {
    camera.aspect = window.innerWidth / (window.innerHeight*0.8);
    camera.updateProjectionMatrix();
    renderer.setSize(window.innerWidth, window.innerHeight*0.8);
});

initScene();
createAgent();
createFood();
initialize();
animate();
