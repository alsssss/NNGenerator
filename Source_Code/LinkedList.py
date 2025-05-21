class Node:
    def __init__(self, data):
        self.data = data 
        self.next = None  
        
class LinkedList:
    def __init__(self):
        self.head = None
        self.last = None
    
    def printList(self):
        temp = self.head 
        while temp:
            print(temp.data,end=' ') 
            temp = temp.next 
        print()  

    def insertAtEnd(self, new_data):
        new_node = Node(new_data)  
        if self.head is None:
            self.head = new_node
            self.last = new_node 
            return
        self.last.next = new_node
        self.last = self.last.next


if __name__ == '__main__':
    llist = LinkedList()

    llist.insertAtEnd('jumps')
    llist.insertAtEnd('to')
    llist.insertAtEnd('there')

    llist.printList()