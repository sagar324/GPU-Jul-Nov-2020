#include <algorithm>
#include<bits/stdc++.h>
#include <cuda.h>
using namespace std;

class Node{
public:
    
    int size=0;
    bool leaf;
    int keys[9];
    int values[8][20];
    Node* pointers[9];
    Node* next=NULL;//leaf node
    //Node* parent=NULL;

    Node(){
        size=0;
        leaf=false;
    }
};



Node* findpar(Node* child,Node* root){
    if(root->leaf==true||root->pointers[0]->leaf==true){
        return NULL;
    }
    for(int i=0;i<root->size+1;i++){
        if(root->pointers[i]==child){
            return root;
        }
        else if(findpar(child,root->pointers[i])!=NULL){
            return findpar(child,root->pointers[i]);
        }
    }
    return NULL;
}
Node* insertinternal(Node* parent,Node* newchild, Node* root,int val){
    //parent may or may not have overflow
    if(parent->size<7){
        int itr=0;
        while(val>parent->keys[itr]&&itr<parent->size){
            itr++;
        }
        for(int i= parent->size-1;i>=itr;i--){
            parent->keys[i+1] = parent->keys[i];
        }
        for(int i=parent->size;i>itr;i--){
            parent->pointers[i+1] = parent->pointers[i];
        }
        parent->pointers[itr+1] = newchild;
        parent->size++;
        parent->keys[itr] = val;
        return root;
    }    
    //parent has overflow,handle this and call its parent with a new child node
    vector <int> temparray ;
    for(int i=0;i<8;i++){
        temparray.push_back(parent->keys[i]);
    } 
    vector <Node*> temppointers ;
    for(int i=0;i<=8;i++){
        temppointers.push_back(parent->pointers[i]);
    }
    int itr = 0;

    while(val>temparray[itr]&&itr<7){
        itr++;
    }
    for(int i=6;i>=itr;i--){
        temparray[i+1] = temparray[i];
    }
    for(int i=7;i>itr;i--){
        temppointers[i+1] = temppointers[i];
    }

    temppointers[itr+1] = newchild;
    temparray[itr] = val;
    //define new node and distribute keys and links
    Node* internalnode = new Node();
    internalnode->leaf=false;
    internalnode->size=3;
    parent->size = 4;

    for(int i=0;i<parent->size;i++){
        parent->keys[i] = temparray[i];
    }
    for(int i=0;i<5;i++){
        parent->pointers[i] = temppointers[i];
    }
    int transfer = temparray[4];
    for(int i=0;i<3;i++){
        internalnode->keys[i] = temparray[5+i];
    }
    for(int i=0;i<4;i++){
        internalnode->pointers[i] = temppointers[5+i];
    }

    if(parent==root){
        Node* root2 = new Node();
        root2->keys[0] = transfer;
        //root2->pointers[0] = ne atomicAdd(&(ptr->values[i][attr-2]),upd);w Node();
        root2->pointers[0] = parent;
        //root2->pointers[1] = new Node();
        root2->pointers[1] = internalnode;
        root2->size=1;
        root2->leaf=false;
        return root2;
    }
    //write condition if it is root.
    return insertinternal(findpar(parent,root),internalnode,root,transfer);
   
}

Node* insert(Node* root,int val,int m){
    if (root==NULL){
        root = new Node();
        for(int i=0;i<8;i++){
            for(int j=0;j<m-1;j++){
                root->values[i][j] = 0;
            }
        }
        root->leaf=true;
        root->keys[0]=val;
        root->size=1;
        return root;
    }
    Node* ptr = root;
    Node* parent;
    while(ptr->leaf==false){
        parent = ptr;
        for(int i=0;i<ptr->size;i++){
            if(val<ptr->keys[i]){
                ptr = ptr->pointers[i];
                break;
            }
            if(i==ptr->size-1){
                ptr = ptr->pointers[i+1];
                break;
            }
        }
    }
    if(ptr->size<7){
        int i=0;
        while(val>ptr->keys[i]&&i<ptr->size){
            i++;
        }
        for(int itr=ptr->size-1;itr>=i;itr--){
            ptr->keys[itr+1] = ptr->keys[itr];
        }
        ptr->keys[i] = val;

        ptr->size++;
        return root;
    }
    
    //overflow condition
    Node* leaf2 = new Node();
    for(int i=0;i<8;i++){
        for(int j=0;j<m-1;j++){
            leaf2->values[i][j]=0;
        }
    }
    leaf2->leaf=true;
    vector <int> temparray;
    for(int i=0;i<8;i++){
        temparray.push_back(ptr->keys[i]);
    }
    int itr = 0;

    while(val>temparray[itr]&&itr<7){
        itr++;
    }
    for(int i=6;i>=itr;i--){
        temparray[i+1] = temparray[i];
       
    }

    temparray[itr] = val;
    //cout<<itr<<endl;
    ptr->size = 4;
    leaf2->size = 4;
    leaf2->next = ptr->next;
    ptr->next = leaf2;
    //after inserting x,there is possibility that keys of ptr may change
    //so we update keys of both ptr and leaf2
    for(int i=0;i<ptr->size;i++){
        ptr->keys[i] = temparray[i];
    }
    for(int i=0;i<leaf2->size;i++){
        leaf2->keys[i] = temparray[ptr->size+i];
        //cout<<leaf2->keys[i]<<" ";
    }
    //cout<<endl;
    //updates done
    //now overflow mightve happened at root or internal node/leaf
    if(ptr==root){
        
        Node* root2 = new Node();
        
        root2->keys[0] = leaf2->keys[0];
        //root2->pointers[0] = new Node();
        root2->pointers[0] = ptr;
        //root2->pointers[1] = new Node();
        root2->pointers[1] = leaf2;
        root2->size=1;
        root2->leaf=false;
        return root2;
    }
    //overflow happened at some leaf node which is not the root.
    return insertinternal(parent,leaf2,root,leaf2->keys[0]);
}
bool searchtree(Node* root,int val){
    if(root==NULL){
        return false;
    }
    Node* ptr = root;
    while(ptr->leaf==false){
        for(int i=0;i<ptr->size;i++){
            if(val<ptr->keys[i]){
                ptr = ptr->pointers[i];
                break;
            }
            if(i==ptr->size-1){
                ptr=ptr->pointers[i+1];
                break;
            }
        }
    }
    for(int i=0;i<ptr->size;i++){
        if(ptr->keys[i]==val){
            cout<<ptr->keys[i]<<" ";
            for(int j=0;j<ptr->size;j++){
                cout<<ptr->values[i][j]<<" ";
            }
            cout<<endl;
            return true;
        }
    }
    return false;
}

__global__ void gpusearch(int n,int m,int num,int *gpuarray,int *gpuoutput, Node* gputree){
    //printf("hi");
    int id = blockIdx.x*blockDim.x+threadIdx.x;
    if(id < num)
    {
    int val = gpuarray[id];
    Node* ptr = gputree;
    for(int i=0;i<m;i++){
        gpuoutput[id*m+i]=-1;
    }
    //printf("%d %d",ptr->keys[0],ptr->keys[1]);
    while(ptr->leaf==false){
        for(int i=0;i<ptr->size;i++){
            if(val<ptr->keys[i]){
                ptr = ptr->pointers[i];
                break;
            }
            if(i==ptr->size-1){
                ptr=ptr->pointers[i+1];
                break;
            }
        }
    }
    for(int i=0;i<ptr->size;i++){
        if(ptr->keys[i]==val){
            gpuoutput[id*m] = val;
            //printf("%d ",val);
            for(int j=0;j<m-1;j++){
                gpuoutput[id*m+1+j] = ptr->values[i][j];
                //printf("%d ",ptr->values[i][j]);
            }
            //printf("\n");
            return;
        }
    }
    //printf("-1\n");
    gpuoutput[id*m]=-1;
    }
    
}

__global__ void gpurange(int n,int m,int num,int *gpuarray,Node* gputree,Node **startpoint){
    int id = blockIdx.x*blockDim.x+threadIdx.x;
    if(id<num)
    {
    int a = gpuarray[2*id];
    int b = gpuarray[2*id+1];
    int itr=0;
    Node* ptr=gputree;
    if(ptr==NULL){
        return;
    }
    while(ptr->leaf==false){
        for(int i=0;i<ptr->size;i++){
            if(a<ptr->keys[i]){
                ptr = ptr->pointers[i];
                break;
            }
            if(i==ptr->size-1){
                ptr=ptr->pointers[i+1];
                break;
            }
        }
    }
    startpoint[id] = ptr->next;
    }
}

__global__  void gpuadd(int n,int m,int num,int *gpuarray,Node* gputree,Node **leafpoint){
    int id = blockIdx.x*blockDim.x+threadIdx.x;
    if(id < num)
    {
    int key = gpuarray[id*3];
    int attr = gpuarray[id*3+1];
    int upd = gpuarray[id*3+2];
    Node* ptr = gputree;
    while(ptr->leaf==false){
        for(int i=0;i<ptr->size;i++){
            if(key<ptr->keys[i]){
                ptr = ptr->pointers[i];
                break;
            }
            if(i==ptr->size-1){
                ptr=ptr->pointers[i+1];
                break;
            }
        }
    }
    for(int i=0;i<ptr->size;i++){
        if(ptr->keys[i]==key){
            //ptr->values[m*i+attr-2] = upd;
            atomicAdd(&(ptr->values[i][attr-2]),upd);
        }
    }
     leafpoint[id] = ptr->next;
    }
}

__global__ void gpupaths(int n,int m,int val,int *gpuoutput,Node* gputree){
    int itr=0;
    Node* ptr = gputree;
    for(int i=0;i<n;i++){
        gpuoutput[i]=-1;
    }
    gpuoutput[itr]=ptr->keys[0];
    itr++;
    while(ptr->leaf==false){
        for(int i=0;i<ptr->size;i++){
            if(val<ptr->keys[i]){
                ptr = ptr->pointers[i];
                gpuoutput[itr]=ptr->keys[0];
                itr++;
                //v.push_back(ptr->keys[0]);
                break;
            }
            if(i==ptr->size-1){
                ptr=ptr->pointers[i+1];
                gpuoutput[itr]=ptr->keys[0];
                itr++;
                //v.push_back(ptr->keys[0]);
                break;
            }
        }
    }
    //v.push_bac
}


Node* gpucopy(Node* ptr){
    Node* temp;
    cudaMalloc(&temp,sizeof(Node));
    cudaMemcpy(temp,ptr,sizeof(Node),cudaMemcpyHostToDevice);
    return temp;
}

Node* copy(Node* head,int m){
    Node* temp = new Node();
    temp->leaf = head->leaf;
    temp->size=head->size;
    for(int i=0;i<8;i++){
        temp->keys[i] = head->keys[i];
    }
    //temp->values=head->values;
    if(head->leaf==true){
        for(int i=0;i<8;i++){
            for(int j=0;j<m-1;j++){
                temp->values[i][j] = head->values[i][j];
            }
        }
        temp->next = head;
        return gpucopy(temp);
    }
    for(int i=0;i<=head->size;i++){   
        temp->pointers[i] = (copy(head->pointers[i],m));
    }
    return gpucopy(temp);
}


void main2 ( int n, int m, int q, int *database, int **queries ,char* outputfilename)  {
    ofstream fout;
    fout.open(outputfilename);
    Node* tree = NULL;
    for(int i=0;i<n;i++){
        tree = insert(tree,database[i*m],m);
    }
    //cout<<tree->keys[0]<<" "<<tree->keys[1]<<endl;
    Node* gputree = copy(tree,m);
    //copy tree into gputree.
    for(int i=0;i<q;i++){
        if(queries[i][0]==1){
            //cout<<"main2";
            int num = queries[i][1];
            int *gpuarray,*gpuoutput,*array;
            array = (int *) malloc(num*sizeof(int));
            cudaMalloc(&gpuoutput,(num*m)*(sizeof(int)));
            cudaMalloc(&gpuarray,num*(sizeof(int)));
            for(int j=0;j<num;j++){
                //cout<<queries[i][2+j]<<" ";
            }
            //cout<<endl;
            for(int j=0;j<num;j++){
                
                array[j] = queries[i][2+j];
                //cout<<queries[i][2+j]<<" ";
                //bool temp = searchtree(tree,queries[i][2+j]);
            }
           // cout<<endl;
            cudaMemcpy(gpuarray,array,num*sizeof(int),cudaMemcpyHostToDevice);
            gpusearch<<<11,num/10 + 1>>>(n,m,num,gpuarray,gpuoutput,gputree);
            cudaDeviceSynchronize();
            int *output;
            output = (int *) malloc((num*m)*sizeof(int));
            cudaMemcpy(output,gpuoutput,(num*m)*sizeof(int),cudaMemcpyDeviceToHost);
            for(int j=0;j<num;j++){
                //cout<<"a";
                if(output[j*m]==-1){
                    fout<<"-1"<<endl;
                    continue;
                }
                for(int k=0;k<m;k++){
                    fout<<output[j*m+k]<<" ";
                }
                fout<<endl;
            }
        }
        else if(queries[i][0]==2){
            //continue;
            int num = queries[i][1];
            int *gpuarray,*array;
            array = (int *) malloc((2*num)*sizeof(int));
            cudaMalloc(&gpuarray,(2*num)*sizeof(int));
            for(int j=0;j<2*num;j++){
                array[j] = queries[i][2+j];
            }
            cudaMemcpy(gpuarray,array,(2*num)*sizeof(int),cudaMemcpyHostToDevice);
            Node **startpoint;
            cudaMalloc(&startpoint,num*sizeof(Node*));
            Node **cpustartpoint;
            gpurange<<<11,num/10 + 1>>>(n,m,num,gpuarray,gputree,startpoint);
            cpustartpoint = (Node**)malloc(num*sizeof(Node*));
            cudaMemcpy(cpustartpoint,startpoint,num*sizeof(Node*),cudaMemcpyDeviceToHost);
            for(int j=0;j<num;j++){
                Node* ptr = cpustartpoint[j];
                int a = array[2*j];
                int b = array[2*j+1];
                int itr=0;
                while(ptr!=NULL){
                    for(int k=0;k<ptr->size;k++){
                        if(ptr->keys[k]>=a&&ptr->keys[k]<=b){
                            itr++;
                            fout<<ptr->keys[k]<<" ";
                            for(int l=0;l<m-1;l++){
                                fout<<ptr->values[k][l]<<" ";
                            }
                            fout<<endl;
                        }
                    }
                    ptr=ptr->next;
                }
                if(itr==0){
                    fout<<"-1"<<endl;
                }
            }
        }
        else if(queries[i][0]==3){
            //no output reqd
            int num = queries[i][1];
            int *gpuarray,*array;
            Node **leafpoint,**cpuleafpoint;
            cudaMalloc(&leafpoint,num*sizeof(Node*));
            cpuleafpoint = (Node**) malloc(num*sizeof(Node *));
            array = (int *) malloc((3*num)*sizeof(int));
            cudaMalloc(&gpuarray,(3*num)*sizeof(int));
            for(int j=0;j<3*num;j++){
                array[j] = queries[i][2+j];
            }
            cudaMemcpy(gpuarray,array,(3*num)*sizeof(int),cudaMemcpyHostToDevice);
            gpuadd<<<11,num/10 + 1>>>(n,m,num,gpuarray,gputree,leafpoint);
            cudaMemcpy(cpuleafpoint,leafpoint,num*sizeof(Node*),cudaMemcpyDeviceToHost);
            for(int j=0;j<num;j++){
                Node* ptr= cpuleafpoint[j];
                int key,attr,upd;
                key = array[3*j];
                attr = array[3*j+1];
                upd = array[3*j+2];
                for(int k=0;k<ptr->size;k++){
                     if(ptr->keys[k]==key){
                         ptr->values[k][attr-2] += upd;
                     }                        
                }
            }
        }
        else{
            int *gpuoutput;
            int val = queries[i][1];
            cudaMalloc(&gpuoutput,(n)*sizeof(int)); 
            gpupaths<<<1,1>>>(n,m,val,gpuoutput,gputree);
            int *output;
            output = (int *) malloc(n*sizeof(int));
            cudaMemcpy(output,gpuoutput,n*sizeof(int),cudaMemcpyDeviceToHost);
            for(int i=0;i<n;i++){
                if(output[i]==-1){
                    break;
                }
                fout<<output[i]<<" ";
            }
            fout<<endl;
        }
    }
}

int main(int argc,char **argv){

    //variable declarations
    int n,m,q;
    
    //Input file pointer declaration
    FILE *inputfilepointer;
    
    //File Opening for read
    char *inputfilename = argv[1];
    inputfilepointer    = fopen( inputfilename , "r");
    
    //Checking if file ptr is NULL
    if ( inputfilepointer == NULL )  {
        printf( "input.txt file failed to open." );
        return 0;
    }
    
    
    fscanf( inputfilepointer, "%d", &n );      //scaning for number of rows
    fscanf( inputfilepointer, "%d", &m );      //scaning for number of columns

    int *database = (int *) malloc(n*m*sizeof(int));
    for(int i=0;i<n;i++){
        for(int j=0;j<m;j++){
            fscanf( inputfilepointer, "%d", &database[i*m+j] );
        }
    }
    
    fscanf( inputfilepointer, "%d", &q );      //scanning for number of queries
    int **queries = (int **) malloc(q*sizeof(int *));
    for(int i=0;i<q;i++){
        int typeop;
        fscanf( inputfilepointer, "%d", &typeop );
        if(typeop==4){
            //cout<<"a"<<endl;
            queries[i] = (int *) malloc (2*sizeof(int));
            queries[i][0] = 4;
            fscanf( inputfilepointer, "%d", &queries[i][1]);
        }
        else if(typeop==3){
            //cout<<"b"<<endl;
            int num;
            fscanf( inputfilepointer, "%d", &num );

            queries[i] = (int *) malloc((2+3*num)*sizeof(int));
            queries[i][0] = 3;
            queries[i][1] = num;
            for(int j=0;j<3*num;j++){
                fscanf( inputfilepointer, "%d", &queries[i][2+j] );
            }
        }
        else if(typeop==2){
            //cout<<"c"<<endl;
            int num;
            fscanf( inputfilepointer, "%d", &num );
            queries[i] = (int *) malloc((2+2*num)*sizeof(int));
            queries[i][0] = 2;
            queries[i][1] = num;
            for(int j=0;j<2*num;j++){
                fscanf( inputfilepointer, "%d", &queries[i][2+j] );
            }
        }
        else {
            //cout<<"d"<<endl;
            int num;
            fscanf( inputfilepointer, "%d", &num );
            queries[i] = (int *) malloc((2+num)*sizeof(int));
            queries[i][0] = 1;
            queries[i][1] = num;
            for(int j=0;j<num;j++){
                fscanf( inputfilepointer, "%d", &queries[i][2+j] );
            }
        }
    }
    

    char *outputfilename = argv[2]; 
    
    main2 ( n, m, q, database, queries, outputfilename);
    //cout<<"done";
    fclose( inputfilepointer );
    return 0;
}
