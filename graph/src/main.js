import MultiGraph from "graphology";
import ForceSupervisor from "graphology-layout-force/worker";
import Sigma from "sigma";

export default function myGraph(nodes, edges) {
	const container = document.getElementById("container");

	// Create a graphology graph
	const graph = new MultiGraph();

	nodes.forEach(el => {
		let indentation = (el.match(new RegExp("/", "g")) || []).length
		let color = "blue";
		let label = el;
		let size = 10;

		if (el.startsWith("https://") || el.startsWith("http://")) {
			color = "red";
		};

		if (el.endsWith("/index.md")) {
			label = el.slice(0, -8);
			color = "green";
		}

		if (el == "index.md") {
			color = "black";
			size = 12;
		}

		if (!label.endsWith("/")) {
			indentation += 1;
		}

		if (indentation != 0) {
			size *= (2/indentation);
		}

		graph.addNode(el, { label, x: Math.random() * 100, y: Math.random() * 100, size, color, labelColor: "white" });
	});

	edges.forEach(el => {
		graph.addEdge(el[0], el[1], { size: 1, color: "darkgray" });
	});

	// Create the spring layout and start it
	const layout = new ForceSupervisor(graph, { isNodeFixed: (_, attr) => attr.highlighted });
	layout.start();

	const renderer = new Sigma(graph, container);

	//
	// Drag'n'drop feature
	//

	let draggedNode = null;
	let isDragging = false;

	// On mouse down on node, highlight it
	renderer.on("downNode", (e) => {
		isDragging = true;
		draggedNode = e.node;
		graph.setNodeAttribute(draggedNode, "highlighted", true);
	});

	// Move logic
	renderer.getMouseCaptor().on("mousemovebody", (e) => {
		if (!isDragging || !draggedNode) return;

		const pos = renderer.viewportToGraph(e);

		graph.setNodeAttribute(draggedNode, "x", pos.x);
		graph.setNodeAttribute(draggedNode, "y", pos.y);

		e.preventSigmaDefault();
		e.original.preventDefault();
		e.original.stopPropagation();
	});

	// Mouse up logic
	renderer.getMouseCaptor().on("mouseup", () => {
		if (draggedNode) {
			graph.removeNodeAttribute(draggedNode, "highlighted")
		}

		isDragging = false;
		draggedNode = null;
	});

	// Disable the autoscale at the first down interaction
	renderer.getMouseCaptor().on("mousedown", () => {
		if (!renderer.getCustomBBox()) renderer.setCustomBBox(renderer.getBBox());
	});
}
