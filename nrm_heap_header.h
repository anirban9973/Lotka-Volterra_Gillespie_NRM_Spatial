

//my data structures and function declaration for the next reaction method simulation


// data structure to store both time and site;

struct Element {
  double even;
  double odd;
};

// Custom comparison function to compare even components
bool compareEven(const Element& a, const Element& b) {
  return a.even > b.even; // Change to '>' for min-heap
}

// bubbling up algorithm

int parent(int x) {
  return (x-1) / 2;
}

// place the position of an element correctly inside a loop

void heapify(std::vector<Element>& heap, int index, std::vector<int>& SpatialList) {

  // bubbling up
  if (heap[index].even < heap[(index-1)/2].even) {
    while (heap[index].even < heap[parent(index)].even) {
      int site1 = heap[index].odd; int site2 = heap[parent(index)].odd;
      std::swap(heap[index], heap[parent(index)]);

      // swap the elements in the spatial list
      SpatialList[site1] = parent(index); SpatialList[site2] = index;
      
      index = parent(index);
    }
  }

  // bubbling down
  else {
    int size = heap.size();
    while (true) {
      int leftChild = 2 * index + 1;
      int rightChild = 2 * index + 2;
      int smallest = index;

      // Check if left child exists and is smaller than current index
      if (leftChild < size && heap[leftChild].even < heap[smallest].even) {
	smallest = leftChild;
      }

      // Check if right child exists and is smaller than current index or left child
      if (rightChild < size && heap[rightChild].even < heap[smallest].even) {
	smallest = rightChild;
      }

      // If the smallest element is the current index, stop bubbling down
      if (smallest == index) {
	break;
      }

      int site1 = heap[index].odd; int site2 = heap[smallest].odd;
      
      // Swap the current element with the smallest child
      std::swap(heap[index], heap[smallest]);

      // swap the elements in the spatial list
      SpatialList[site1] = smallest; SpatialList[site2] = index;

      // Move to the smallest child's index and continue bubbling down
      index = smallest;
    }
  }
  
}
