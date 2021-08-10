#include <bits/stdc++.h>
#include <cuda.h>
using namespace std;
//typedefs and flash
int n,m;
ofstream fout;

struct point{
    int left;
    int right;
};

struct priorpoint{
    double fvalue;
    int left;
    int right;
    struct priorpoint* next;
};

struct node 
{ 
    int parent_row, parent_column; 
    double f, g, h; 
}; 


class compare{
    public:
    int operator() (const priorpoint& priorpoint1, const priorpoint& priorpoint2){
        return priorpoint1.fvalue > priorpoint2.fvalue;
    }
};



double doublemin(double d1,double d2){
    if(d1<d2){
        return d1;
    }
    return d2;
}
__device__ double doublemingpu(double d1,double d2){
    if(d1<d2){
        return d1;
    }
    return d2;
}
// A Utility Function to check whether given node (row, col) 
// is a Valid node or not. 
bool Valid(int row, int col,int *grid) 
{ 
    // Returns true if row number and column number 
    // is in range 
    if(row>=0&&row<n){
        if(col>=0&&col<m){
            if(grid[row*m+col]>=0){
                return true;
            }
        }
    } 
    return false;
} 

__device__ bool Validgpu(int row, int col,int *grid,int n,int m) 
{ 
    // Returns true if row number and column number 
    // is in range 
    if(row>=0&&row<n){
        if(col>=0&&col<m){
            if(grid[row*m+col]>=0){
                return true;
            }
        }
    } 
    return false;
} 

// A Utility Function to check whether destination node has 
// been reached or not 
bool Dest(int row, int col, point dest) 
{ 
    if (row == dest.left && col == dest.right){
        return true; 
    } 
    return false;
} 


// A Utility Function to calculate the 'h' heuristics. 
double Hestimate(int currow, int curcol, int destrow,int destcol) 
{ 
    int ll = currow-destrow;
    int rr = curcol-destcol;
    if(ll<0){
        ll=-ll;
    }
    if(rr<0){
        rr=-rr;
    }
    ll = ll + rr;
    double dd = ll;
    return dd;
} 

__device__ double Hestimategpu(int currow, int curcol, int destrow,int destcol) 
{ 
    int ll = currow-destrow;
    int rr = curcol-destcol;
    if(ll<0){
        ll=-ll;
    }
    if(rr<0){
        rr=-rr;
    }
    ll = ll + rr;
    double dd = ll;
    return dd;
} 


void path_trace(struct node** nodematrix, point dest, int hops){
    int row = dest.left;
    int col = dest.right;

    if((nodematrix[row][col].parent_row == row 
            && nodematrix[row][col].parent_column == col )){
        fout<<"The number of hops = "<<hops<<endl;
        fout<<"The path is =>"<<endl;
        fout<<"("<<row<<","<<col<<")";
        return;
    }
    int temp_row = nodematrix[row][col].parent_row; 
    int temp_col = nodematrix[row][col].parent_column; 
    int row2 = temp_row; 
    int col2 = temp_col;
    dest.left = row2;
    dest.right = col2;
    path_trace(nodematrix,dest,hops+1);
    fout<<"->";
    fout<<"("<<row<<","<<col<<")";
    if(hops==0){
        fout<<endl;
        fout<<"The cost of the optimal path is = "<<nodematrix[row][col].g<<endl;
    }
    return;
}

void path_trace2(struct node *nodematrix, point dest, int hops,int n,int m){
    int row = dest.left;
    int col = dest.right;

    if((nodematrix[row*m+col].parent_row == row 
            && nodematrix[row*m+col].parent_column == col )){
        fout<<"The number of hops = "<<hops<<endl;
        fout<<"The path is =>"<<endl;
        fout<<"("<<row<<","<<col<<")";
        return;
    }
    int temp_row = nodematrix[row*m+col].parent_row; 
    int temp_col = nodematrix[row*m+col].parent_column; 
    int row2 = temp_row; 
    int col2 = temp_col;
    dest.left = row2;
    dest.right = col2;
    path_trace2(nodematrix,dest,hops+1,n,m);
    fout<<"->";
    fout<<"("<<row<<","<<col<<")";
    if(hops==0){
        fout<<endl;
        fout<<"The cost of the optimal path is = "<<nodematrix[row*m+col].g<<endl;
    }
    return;
}

__device__ struct priorpoint* push1gpu(int i,int j,double f){
    struct priorpoint* temp;
    temp = (struct priorpoint*)malloc(sizeof(struct priorpoint));
    temp->fvalue = f;
    temp->left = i;
    temp->right = j;
    temp ->next = NULL;
    return temp;
}
__device__ struct priorpoint* push2gpu(int i,int j,double f,struct priorpoint* head){
    struct priorpoint* ptr;
    ptr = head;
    if(ptr->fvalue>f){
        struct priorpoint *temp;
        temp = (struct priorpoint*)malloc(sizeof(struct priorpoint));
        temp->fvalue = f;
        temp->left = i;
        temp->right = j;
        temp->next = head;
        return temp;
    }
    while((ptr->next !=NULL)&&((ptr->next)->fvalue<f)){
        ptr = ptr->next;
    }
    struct priorpoint *temp;
    temp = (struct priorpoint*)malloc(sizeof(struct priorpoint));
    temp->fvalue=f;
    temp->left = i;
    temp->right = j;
    if(ptr->next==NULL){
        temp->next = NULL;
        ptr->next = temp;
        return head;
    }
    else{
        temp->next = (ptr->next);
        ptr->next = temp;
        return head;
    }
}


struct priorpoint* push1cpu(int i,int j,double f){
    struct priorpoint* temp;
    temp = (struct priorpoint*)malloc(sizeof(struct priorpoint));
    temp->fvalue = f;
    temp->left = i;
    temp->right = j;
    temp ->next = NULL;
    return temp;
}

struct priorpoint* push2cpu(int i,int j,double f,struct priorpoint* head){
    struct priorpoint* ptr;
    ptr = head;
    if(ptr->fvalue>f){
        struct priorpoint *temp;
        temp = (struct priorpoint*)malloc(sizeof(struct priorpoint));
        temp->fvalue = f;
        temp->left = i;
        temp->right = j;
        temp->next = head;
        return temp;
    }
    while((ptr->next !=NULL)&&((ptr->next)->fvalue<f)){
        ptr = ptr->next;
    }
    struct priorpoint *temp;
    temp = (struct priorpoint*)malloc(sizeof(struct priorpoint));
    temp->fvalue=f;
    temp->left = i;
    temp->right = j;
    if(ptr->next==NULL){
        temp->next = NULL;
        ptr->next = temp;
        return head;
    }
    else{
        temp->next = (ptr->next);
        ptr->next = temp;
        return head;
    }
}

void astar(struct node** nodematrix,int *grid,struct point src,struct point dest){
    if (Valid (src.left, src.right,grid) == false || Valid (dest.left, dest.right,grid) == false) 
    { 
        printf ("Source or dest is inValid\n"); 
        return; 
    } 

    if (Dest(src.left, src.right, dest) == true) 
    { 
        printf ("We are already at the destination\n"); 
        return; 
    }
    bool visited[n][m]; 
    for(int i=0;i<n;i++){
        for(int j=0;j<m;j++){
            visited[i][j]=false;
        }
    }

    int i, j; 

    i = src.left, j = src.right; 
    

    struct priorpoint* head;
    // struct priorpoint* tail;
    head = NULL;
    // tail = NULL;
    head = push1cpu(i,j,0);
    // tail = head;
    bool foundDest = false; 
    int count = 0;
    while (head != NULL) 
    { 
        count++;
        struct priorpoint  temp;
        temp.fvalue = head->fvalue;
        temp.left = head->left;
        temp.right = head->right;
        head = head->next;


        // Add this vertex to the closed list 
        i = temp.left; 
        j = temp.right; 
        visited[i][j] = true; 
        if(count == 20){
            //fout<<i<<" "<<j<<endl;
        }
        // To store the 'g', 'h' and 'f' of the 4 successors 
        double g2, h2, f2; 
        int vi, vj;
        int xx[8] = {-1, 0, 1, 0,1,1,-1,-1};
        int yy[8] = {0, 1, 0, -1,1,-1,1,-1};

        for(int pind = 0; pind<8; pind++){
            if(pind == 0){
           // printf("inside astarcpu\n");
        }
            
            vi = i + xx[pind];
            vj = j + yy[pind];
            
            if (Valid(vi, vj,grid) == true) 
            { 
                // If the destination node is the same as the current successor 
                if (Dest(vi, vj, dest) == true) 
                { 
                    // Set the Parent of the destination node 

                    nodematrix[vi][vj].parent_row = i; 
                    nodematrix[vi][vj].parent_column = j; 
                    g2 = nodematrix[i][j].g + grid[vi*m+vj]; 
                    h2 = Hestimate (vi, vj, dest.left, dest.right); 
                    f2 = g2 + h2;
                    nodematrix[vi][vj].f = f2; 
                    nodematrix[vi][vj].g = g2; 
                    nodematrix[vi][vj].h = h2;
                    foundDest = true; 
                    return; 
                } 
                // If the successor is nit visited
                if (!visited[vi][vj]) 
                { 
                    g2 = nodematrix[i][j].g + grid[vi*m+vj]; 
                    h2 = Hestimate (vi, vj, dest.left, dest.right); 
                    f2 = g2 + h2; 

                    // if the adjacent node is not in the minHeap insert it
                    //if it is present in the minHeap and the newer f is smaller than alreayy entered f than update
                    if(nodematrix[vi][vj].f > f2){
                        if(head == NULL){
                            head = push1cpu(vi,vj,f2);
                            // tail = head;
                        }else{
                            head = push2cpu(vi,vj,f2,head);
                        }
   
                        // Update the details of this node 
                        nodematrix[vi][vj].f = f2; 
                        nodematrix[vi][vj].g = g2; 
                        nodematrix[vi][vj].h = h2; 
                        nodematrix[vi][vj].parent_row = i; 
                        nodematrix[vi][vj].parent_column = j; 
                    }
                }
            }
        }
    }
    if(foundDest==false){
        //fout<<"Destination not found\n";
    }
}

void Nodematrixupdate(struct node** nodematrix,int *grid,int x,int y,point dest){
    
    bool visited[n][m]; 
    for(int i=0;i<n;i++){
        for(int j=0;j<m;j++){
            visited[i][j]=false;
        }
    }
  
    int i, j; 

    i = x, j = y; 

    //initializing the added edge
    nodematrix[i][j].h = Hestimate(i,j,dest.left,dest.right);
    int XX[8] = {-1, 0, 1, 0,1,1,-1,-1};
    int YY[8] = {0, 1, 0, -1,1,-1,1,-1};
    double ming = nodematrix[i][j].g;
    int minindex=0;
    for(int pind=0;pind<8;pind++){
        int vi,vj;
        vi = i+XX[pind];
        vj = j+YY[pind];
        if(Valid(vi,vj,grid)){
            if(nodematrix[vi][vj].g<ming){
                ming = nodematrix[vi][vj].g;
                minindex = pind;
            }
        }
    }
    int parx,pary;
    parx = i+XX[minindex];
    pary = j+YY[minindex];
    nodematrix[i][j].g = ming+grid[i*m+j];
    nodematrix[i][j].f = ming+nodematrix[i][j].h;
    nodematrix[i][j].parent_row = parx;
    nodematrix[i][j].parent_column = pary;
    // finished initialisation
    //printf("%d %d\n",nodematrix[1][6].parent_row,nodematrix[1][6].parent_column);
    struct priorpoint* head;
    // struct priorpoint* tail;
    head = NULL;
    // tail = NULL;
    head = push1cpu(i,j,nodematrix[i][j].f);
    // tail = head;
    while (head != NULL) 
    { 
        struct priorpoint  temp;
        temp.fvalue = head->fvalue;
        temp.left = head->left;
        temp.right = head->right;
        head = head->next;


        // Add this vertex to the closed list 
        i = temp.left; 
        j = temp.right; 
        visited[i][j] = true; 
    
        // To store the 'g', 'h' and 'f' of the 4 successors 
        double g2, h2, f2; 
        int vi, vj;
        int xx[8] = {-1, 0, 1, 0,1,1,-1,-1};
        int yy[8] = {0, 1, 0, -1,1,-1,1,-1};

        for(int pind = 0; pind<8; pind++){
            
            vi = i + xx[pind];
            vj = j + yy[pind];
            
            if (Valid(vi, vj,grid) == true) 
            { 
                // If the destination node is the same as the current 
                // If the successor is not visited
                if (!visited[vi][vj]) 
                {   

                    g2 = doublemin(nodematrix[vi][vj].g,nodematrix[i][j].g + grid[vi*m+vj]); 
                    h2 = Hestimate (vi, vj, dest.left, dest.right); 
                    f2 = g2 + h2; 

                    // if the adjacent node is not in the minHeap insert it
                    //if it is present in the minHeap and the newer f is smaller than alreayy entered f than update
                    if(nodematrix[vi][vj].f > f2){
                        if(head == NULL){
                            head = push1cpu(vi,vj,f2);
                            // tail = head;
                        }else{
                            head = push2cpu(vi,vj,f2,head);
                        }
   
                        // Update the details of this node 
                        nodematrix[vi][vj].f = f2; 
                        nodematrix[vi][vj].g = g2; 
                        nodematrix[vi][vj].h = h2; 
                        nodematrix[vi][vj].parent_row = i; 
                        nodematrix[vi][vj].parent_column = j; 
                    }
                }
            }
        }
    }
}




__global__ void setvisited(bool* visited,int n,int m){
    int id = (blockIdx.x)*blockDim.x + threadIdx.x;
    if(id < n*m){
        visited[id] = false;
    }
}



__global__ void setpushpq(int* pushpq){
    int id = threadIdx.x;
    if(id < 8){
    pushpq[id] = 0;}
}


__global__ void astargpu(struct node *nodematrix, int *grid, int srcx,int srcy,int destx,int desty,int n,int m,bool* visited){
    for(int i=0;i<n;i++){
        for(int j=0;j<m;j++){
            int id = i*m+j;
            visited[id] = false;
        }
    }  
    //printf("Hello-1\n");
    // for(int i=0;i<n;i++){
    //     for(int j=0;j<m;j++){
    //         visited[i*m+j]=false;
    //     }
    // }

    int i, j; 
    i = srcx, j = srcy; 
    
    struct priorpoint* head;
    
    head = NULL;
  
    head = push1gpu(i,j,0);
    //printf("Hello-2\n");
    bool foundDest = false; 
  
    int count = 0;
    int num1=0;
    while (head != NULL&&foundDest==false) 
    { 
        count++;
        struct priorpoint  temp;
        temp.fvalue = head->fvalue;
        temp.left = head->left;
        temp.right = head->right;
        head = head->next;
    //printf("Hello 3,1st loop\n");
        // Add this vertex to the closed list 

        i = temp.left; 
        j = temp.right; 
        visited[i*m+j] = true; 
       
        // To store the 'g', 'h' and 'f' of the 4 successors 
        //int vi, vj;
        int xx[8] = {-1, 0, 1, 0,1,1,-1,-1};
        int yy[8] = {0, 1, 0, -1,1,-1,1,-1};
        
        for(int itr=0;itr<8;itr++){

            int vi,vj;
            vi = i + xx[itr];
            vj = j + yy[itr];
            double f2,g2,h2;
    
            if(Validgpu(vi,vj,grid,n,m)){
                if(vi==destx&&vj==desty){
                    nodematrix[vi*m+vj].parent_row = i; 
                    nodematrix[vi*m+vj].parent_column = j; 
                    g2 = nodematrix[i*m+j].g + grid[vi*m+vj]; 
                    h2 = Hestimategpu (vi, vj, destx, desty); 
                    f2 = g2 + h2;
                    nodematrix[vi*m+vj].f = f2; 
                    nodematrix[vi*m+vj].g = g2; 
                    nodematrix[vi*m+vj].h = h2;
                    //pushpq[threadIdx.x]=2;
                    foundDest = true; 
                }
                if(!visited[vi*m+vj]){
                    g2 = nodematrix[i*m+j].g + grid[vi*m+vj]; 
                    h2 = Hestimategpu (vi, vj, destx, desty); 
                    f2 = g2 + h2;
                    if(nodematrix[vi*m+vj].f > f2){
                        if(head==NULL){
                            head = push1gpu(vi,vj,f2);
                        }
                        else{
                        //num1++;
                             head = push2gpu(vi,vj,f2,head);        
                        }
                        // Update the details of this node 
                        nodematrix[vi*m+vj].f = f2; 
                        nodematrix[vi*m+vj].g = g2; 
                        nodematrix[vi*m+vj].h = h2; 
                        nodematrix[vi*m+vj].parent_row = i; 
                        nodematrix[vi*m+vj].parent_column = j; 
                    }
                }
            }
        }
    }
}

__global__ void astargpuleveltwo(struct node *nodematrix, int *grid,int destx,int desty,int *pushpq, int n,int m,int i,int j,bool* visited){
    int xx[8] = {-1, 0, 1, 0,1,1,-1,-1};
    int yy[8] = {0, 1, 0, -1,1,-1,1,-1};
    int vi,vj;
    vi = i + xx[threadIdx.x];
    vj = j + yy[threadIdx.x];
    double f2,g2,h2;
    
    if(Validgpu(vi,vj,grid,n,m)){
        if(vi==destx&&vj==desty){
            nodematrix[vi*m+vj].parent_row = i; 
            nodematrix[vi*m+vj].parent_column = j; 
            g2 = nodematrix[i*m+j].g + grid[vi*m+vj]; 
            h2 = Hestimategpu (vi, vj, destx, desty); 
            f2 = g2 + h2;
            nodematrix[vi*m+vj].f = f2; 
            nodematrix[vi*m+vj].g = g2; 
            nodematrix[vi*m+vj].h = h2;
            pushpq[threadIdx.x]=2;
            //foundDest = true; 
        }
        if(!visited[vi*m+vj]){
            g2 = nodematrix[i*m+j].g + grid[vi*m+vj]; 
            h2 = Hestimategpu (vi, vj, destx, desty); 
            f2 = g2 + h2;
            if(nodematrix[vi*m+vj].f > f2){
                  pushpq[threadIdx.x] = 1;
                  // Update the details of this node 
                  nodematrix[vi*m+vj].f = f2; 
                  nodematrix[vi*m+vj].g = g2; 
                  nodematrix[vi*m+vj].h = h2; 
                  nodematrix[vi*m+vj].parent_row = i; 
                  nodematrix[vi*m+vj].parent_column = j; 
            }
        }
    }
}
__global__ void astargpulevelone(struct node *nodematrix, int *grid, int srcx,int srcy,int destx,int desty,int n,int m,bool* visited,int* pushpq){
    setvisited<<<n,m>>>(visited,n,m);
    cudaDeviceSynchronize();
    //printf("Hello-1\n");
    // for(int i=0;i<n;i++){
    //     for(int j=0;j<m;j++){
    //         visited[i*m+j]=false;
    //     }
    // }

    int i, j; 
    i = srcx, j = srcy; 
    
    struct priorpoint* head;
    
    head = NULL;
  
    head = push1gpu(i,j,0);
    //printf("Hello-2\n");
    bool foundDest = false; 
  
    int count = 0;
    int num1=0;
    while (head != NULL&&foundDest==false) 
    { 
        count++;
        struct priorpoint  temp;
        temp.fvalue = head->fvalue;
        temp.left = head->left;
        temp.right = head->right;
        head = head->next;
    //printf("Hello 3,1st loop\n");
        // Add this vertex to the closed list 

        i = temp.left; 
        j = temp.right; 
        visited[i*m+j] = true; 
       
        // To store the 'g', 'h' and 'f' of the 4 successors 
        int vi, vj;
        int xx[8] = {-1, 0, 1, 0,1,1,-1,-1};
        int yy[8] = {0, 1, 0, -1,1,-1,1,-1};
        setpushpq<<<1,8>>>(pushpq);
        cudaDeviceSynchronize();
        astargpuleveltwo<<<1,8>>>(nodematrix,grid,destx,desty,pushpq,n,m,i,j,visited);
        cudaDeviceSynchronize();
        
        //check statement
        
        
        for(int itr=0;itr<8;itr++){
            vi = i+xx[itr];
            vj = j+yy[itr];
            if(pushpq[itr]==1){
                if(head==NULL){
                    head = push1gpu(vi,vj,nodematrix[vi*m+vj].f);
                }
                else{
                    num1++;
                    head = push2gpu(vi,vj,nodematrix[vi*m+vj].f,head);        
                }
            }
            else if(pushpq[itr]==2){
                foundDest=true;
            }
        }
    }
}

__global__ void Nodematrixupdategpu(struct node *nodematrix,int *grid,int x,int y,int e,int destx,int desty,int n,int m,bool* visited){
    grid[x*m+y] = e;
    for(int i=0;i<n;i++){
        for(int j=0;j<m;j++){
            int id = i*m+j;
            visited[id] = false;
        }
    }  
    // for(int i=0;i<n;i++){
    //     for(int j=0;j<m;j++){
    //         visited[i*m+j]=false;
    //     }
    // }

    int i, j; 
    i = x, j = y; 
    
    nodematrix[i*m+j].h = Hestimategpu(i,j,destx,desty);
    int XX[8] = {-1, 0, 1, 0,1,1,-1,-1};
    int YY[8] = {0, 1, 0, -1,1,-1,1,-1};
    double ming = nodematrix[i*m+j].g;
    int minindex=0;
    for(int pind=0;pind<8;pind++){
        int vi,vj;
        vi = i+XX[pind];
        vj = j+YY[pind];
        if(Validgpu(vi,vj,grid,n,m)){
            if(nodematrix[vi*m+vj].g<ming){
                ming = nodematrix[vi*m+vj].g;
                minindex = pind;
            }
        }
    }
    int parx,pary;
    parx = i+XX[minindex];
    pary = j+YY[minindex];
    nodematrix[i*m+j].g = ming+grid[i*m+j];
    nodematrix[i*m+j].f = ming+nodematrix[i*m+j].h;
    nodematrix[i*m+j].parent_row = parx;
    nodematrix[i*m+j].parent_column = pary;
    //printf("%d %d\n",nodematrix[m+6].parent_row,nodematrix[m+6].parent_column);    
    struct priorpoint* head;
    // struct priorpoint* tail;
    head = NULL;
    // tail = NULL;
    head = push1gpu(i,j,nodematrix[i*m+j].f);
    // tail = head; 
    while (head != NULL) 
    { 
        struct priorpoint  temp;
        temp.fvalue = head->fvalue;
        temp.left = head->left;
        temp.right = head->right;
        head = head->next;
        // Add this vertex to the closed list 
        i = temp.left; 
        j = temp.right; 
        visited[i*m+j] = true; 
    
        // To store the 'g', 'h' and 'f' of the 4 successors 
        //int vi, vj;
        int xx[8] = {-1, 0, 1, 0,1,1,-1,-1};
        int yy[8] = {0, 1, 0, -1,1,-1,1,-1};

        cudaDeviceSynchronize();
        //for(int pind = 0; pind<8; pind++){}
        for(int itr=0;itr<8;itr++){
            int vi,vj;
            double f2,g2,h2;
            vi = i + xx[itr];
            vj = j + yy[itr];
    
            if (Validgpu(vi, vj,grid,n,m) == true) 
            { 
                // If the destination node is the same as the current 
                // If the successor is not visited
                if (!visited[vi*m+vj]) 
                {   
                    g2 = doublemingpu(nodematrix[vi*m+vj].g,nodematrix[i*m+j].g + grid[vi*m+vj]); 
                    h2 = Hestimategpu (vi, vj, destx, desty); 
                    f2 = g2 + h2; 
                    // if the adjacent node is not in the minHeap insert it
                    //if it is present in the minHeap and the newer f is smaller than alreayy entered f than update
                    if(nodematrix[vi*m+vj].f > f2){
                    
                        if(head==NULL){
                            head = push1gpu(vi,vj,f2);
                        }
                        else{
                            head = push2gpu(vi,vj,f2,head);
                        }
                        // Update the details of this node 
                        nodematrix[vi*m+vj].f = f2; 
                        nodematrix[vi*m+vj].g = g2; 
                        nodematrix[vi*m+vj].h = h2; 
                        nodematrix[vi*m+vj].parent_row = i; 
                        nodematrix[vi*m+vj].parent_column = j; 
                    }
                }
            } 
        }
    }
}

__global__ void Nodematrixupdategpuleveltwo(struct node *nodematrix,int *grid,int destx,int desty,bool* visited,int i,int j,int n,int m,int *pushpq){
    int xx[8] = {-1, 0, 1, 0,1,1,-1,-1};
    int yy[8] = {0, 1, 0, -1,1,-1,1,-1};
    int vi,vj;
    double f2,g2,h2;
    vi = i + xx[threadIdx.x];
    vj = j + yy[threadIdx.x];
    
    if (Validgpu(vi, vj,grid,n,m) == true) 
            { 
                // If the destination node is the same as the current 
                // If the successor is not visited
                if (!visited[vi*m+vj]) 
                {   
                    g2 = doublemingpu(nodematrix[vi*m+vj].g,nodematrix[i*m+j].g + grid[vi*m+vj]); 
                    h2 = Hestimategpu (vi, vj, destx, desty); 
                    f2 = g2 + h2; 
                    // if the adjacent node is not in the minHeap insert it
                    //if it is present in the minHeap and the newer f is smaller than alreayy entered f than update
                    if(nodematrix[vi*m+vj].f > f2){
                    
                        pushpq[threadIdx.x] = 1;
                        // Update the details of this node 
                        nodematrix[vi*m+vj].f = f2; 
                        nodematrix[vi*m+vj].g = g2; 
                        nodematrix[vi*m+vj].h = h2; 
                        nodematrix[vi*m+vj].parent_row = i; 
                        nodematrix[vi*m+vj].parent_column = j; 
                    }
                }
            } 
}
__global__ void Nodematrixupdategpulevelone(struct node *nodematrix,int *grid,int x,int y,int e,int destx,int desty,int n,int m,bool* visited,int* pushpq){
    grid[x*m+y] = e;
    setvisited<<<n,m>>>(visited,n,m);
    cudaDeviceSynchronize();
    // for(int i=0;i<n;i++){
    //     for(int j=0;j<m;j++){
    //         visited[i*m+j]=false;
    //     }
    // }

    int i, j; 
    i = x, j = y; 
    
    nodematrix[i*m+j].h = Hestimategpu(i,j,destx,desty);
    int XX[8] = {-1, 0, 1, 0,1,1,-1,-1};
    int YY[8] = {0, 1, 0, -1,1,-1,1,-1};
    double ming = nodematrix[i*m+j].g;
    int minindex=0;
    for(int pind=0;pind<8;pind++){
        int vi,vj;
        vi = i+XX[pind];
        vj = j+YY[pind];
        if(Validgpu(vi,vj,grid,n,m)){
            if(nodematrix[vi*m+vj].g<ming){
                ming = nodematrix[vi*m+vj].g;
                minindex = pind;
            }
        }
    }
    int parx,pary;
    parx = i+XX[minindex];
    pary = j+YY[minindex];
    nodematrix[i*m+j].g = ming+grid[i*m+j];
    nodematrix[i*m+j].f = ming+nodematrix[i*m+j].h;
    nodematrix[i*m+j].parent_row = parx;
    nodematrix[i*m+j].parent_column = pary;
    //printf("%d %d\n",nodematrix[m+6].parent_row,nodematrix[m+6].parent_column);    
    struct priorpoint* head;
    // struct priorpoint* tail;
    head = NULL;
    // tail = NULL;
    head = push1gpu(i,j,nodematrix[i*m+j].f);
    // tail = head; 
    while (head != NULL) 
    { 
        struct priorpoint  temp;
        temp.fvalue = head->fvalue;
        temp.left = head->left;
        temp.right = head->right;
        head = head->next;
        // Add this vertex to the closed list 
        i = temp.left; 
        j = temp.right; 
        visited[i*m+j] = true; 
    
        // To store the 'g', 'h' and 'f' of the 4 successors 
        int vi, vj;
        int xx[8] = {-1, 0, 1, 0,1,1,-1,-1};
        int yy[8] = {0, 1, 0, -1,1,-1,1,-1};
        setpushpq<<<1,8>>>(pushpq);
        cudaDeviceSynchronize();
        //for(int pind = 0; pind<8; pind++){}
        Nodematrixupdategpuleveltwo<<<1,8>>>(nodematrix,grid,destx,desty,visited,i,j,n,m,pushpq);
        cudaDeviceSynchronize();//check statement
        for(int itr=0;itr<8;itr++){
            vi = i+xx[itr];
            vj = j+yy[itr];
            if(pushpq[itr]==1){
                if(head==NULL){
                    head = push1gpu(vi,vj,nodematrix[vi*m+vj].f);
                }
                else{
                    head = push2gpu(vi,vj,nodematrix[vi*m+vj].f,head);
                }
            }
        }
    }
    //printf("%d %d\n",nodematrix[m+6].parent_row,nodematrix[m+6].parent_column);
}
__global__ void Nodematrixtrivial(struct node *nodematrix,int *grid,int x,int y,int e,int destx,int desty,int n,int m){
    nodematrix[x*m+y].h = Hestimategpu(x,y,destx,desty);
    grid[x*m+y] = e;
}

__global__ void initialize(struct node *nodematrix,int n,int m,int srcx,int srcy){
    int id = ((blockIdx.x)*m)+threadIdx.x;

    if(id<n*m){
        if(id == (srcx*m)+srcy){
            //printf("srid %d\n",id);
            nodematrix[id].f=0;
            nodematrix[id].g=0;
            nodematrix[id].h=0;
            nodematrix[id].parent_row=srcx;
            nodematrix[id].parent_column=srcy;
        }
        else{
            //printf("id %d\n",id);
            nodematrix[id].f=FLT_MAX;
            nodematrix[id].g=FLT_MAX;
            nodematrix[id].h=FLT_MAX;
            nodematrix[id].parent_row=-1;
            nodematrix[id].parent_column=-1;
        }

    }
}

__global__ void initialize2(struct node *nodematrix,int n,int m,int srcx,int srcy){
    for(int i1=0;i1<n;i1++){
        for(int j1=0;j1<m;j1++){
            int id = i1*m+j1;
            if(id == (srcx*m)+srcy){
                //printf("srid %d\n",id);
                nodematrix[id].f=0;
                nodematrix[id].g=0;
                nodematrix[id].h=0;
                nodematrix[id].parent_row=srcx;
                nodematrix[id].parent_column=srcy;
            }
            else{
                //printf("id %d\n",id);
                nodematrix[id].f=FLT_MAX;
                nodematrix[id].g=FLT_MAX;
                nodematrix[id].h=FLT_MAX;
                nodematrix[id].parent_row=-1;
                nodematrix[id].parent_column=-1;
            }
        }
    }
}


int main(){ 
    //event-1 start

    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);
    float milliseconds = 0;
    cudaEventRecord(start,0);

  FILE *inputfilepointer;
    char *inputfilename = "input.txt";
    inputfilepointer    = fopen( inputfilename , "r");
    char *outputfilename = "output.txt";
        fout.open(outputfilename);
    //fout<<"outputfile ha s been opened"<<endl;
     //Checking if file ptr is NULL
     if ( inputfilepointer == NULL )  {
           printf( "input.txt file failed to open." );
               return 0;
     }
    fscanf( inputfilepointer, "%d", &n );      //scaning for number of rows
    fscanf( inputfilepointer, "%d", &m );

    int *grid;
    grid = (int *)malloc(n*m*sizeof(int));
    for(int i=0;i<n;i++){
        for(int j=0;j<m;j++){
            int temp;
            fscanf( inputfilepointer, "%d", &temp );
            grid[i*m+j] = temp;
        }   
    }

    int srcx,srcy,destx,desty,Q;
    fscanf( inputfilepointer, "%d", &srcx );
fscanf( inputfilepointer, "%d", &srcy );
fscanf( inputfilepointer, "%d", &destx );
fscanf( inputfilepointer, "%d", &desty );
fscanf( inputfilepointer, "%d", &Q );


    struct point src,dest;
    src.left = srcx;
    src.right= srcy;
    dest.left = destx;
    dest.right = desty; 

    
    struct node** nodematrix;
    nodematrix = (struct node**)malloc(n*sizeof(struct node*));

    int i, j; 
    for(i=0;i<n;i++){
        nodematrix[i] = (struct node*)malloc(m*sizeof(struct node));
    }
    
    for (i=0; i<n; i++) 
    { 
        for (j=0; j<m; j++) 
        { 
            nodematrix[i][j].f = FLT_MAX; 
            nodematrix[i][j].g = FLT_MAX; 
            nodematrix[i][j].h = FLT_MAX; 
            nodematrix[i][j].parent_row = -1; 
            nodematrix[i][j].parent_column = -1; 
        } 
    }

    i = src.left, j = src.right; 
    nodematrix[i][j].f = 0.0; 
    nodematrix[i][j].g = 0.0; 
    nodematrix[i][j].h = 0.0; 
    nodematrix[i][j].parent_row = i; 
    nodematrix[i][j].parent_column = j; 
    int depth = 0;
    fout<<"CPU OUTPUT"<<endl;
    for(int itr=0;itr<Q;itr++){
        int op;
    fscanf( inputfilepointer, "%d", &op );
        if(op==7){
            if(depth == 0){
                astar(nodematrix,grid, src, dest); 
                depth++;
            }
            if(nodematrix[destx][desty].g == FLT_MAX){
                fout<<"The destination node is not found"<<endl;
                continue;
            }
            fout<<"The destination node is found\n"; 
            path_trace (nodematrix, dest,0); 
            fout<<"---------------------------------------------\n";
            
            continue;
        }
        int edges;
        fscanf( inputfilepointer, "%d", &edges );
        for(int itr1=0;itr1<edges;itr1++){
            int x,y,e;
            fscanf( inputfilepointer, "%d", &x );
        fscanf( inputfilepointer, "%d", &y );
            fscanf( inputfilepointer, "%d", &e );
            grid[x*m+y] = e;
            int num =0;
            int xx[8] = {-1, 0, 1, 0,1,1,-1,-1};
            int yy[8] = {0, 1, 0, -1,1,-1,1,-1};
            for(int it=0;it<8;it++){
                int a,b;
                a= x + xx[it];
                b = y + yy[it];
                if(grid[a*m+b] != -1){
                    num++;
                }
            }
            if(num == 0){
                nodematrix[x][y].h = Hestimate(x,y,destx,desty);
                continue;
            }
            Nodematrixupdate(nodematrix,grid,x,y,dest);
        }
        fout<<"Edges added"<<endl;
        fout<<"---------------------------------------------"<<endl;
    }   
    //event-1 ended



    cudaEventRecord(stop,0);
    cudaEventSynchronize(stop);
    cudaEventElapsedTime(&milliseconds, start, stop);
    printf("Time taken by CPU to execute is: %.6f ms\n", milliseconds);

    //event-2 starts

    cudaEvent_t start1, stop1;
    cudaEventCreate(&start1);
    cudaEventCreate(&stop1);
    float milliseconds1 = 0;
    cudaEventRecord(start1,0);

    fout<<"GPU OUTPUT"<<endl;
    fclose(inputfilepointer);
    inputfilepointer    = fopen( inputfilename , "r");
    fscanf( inputfilepointer, "%d", &n );      //scaning for number of rows
    fscanf( inputfilepointer, "%d", &m );
    int *cpugrid,*gpugrid;
    cpugrid = (int*)malloc(n*m*sizeof(int));
    cudaMalloc(&gpugrid,n*m*sizeof(int));
    for(int i=0;i<n;i++){
        for(int j=0;j<m;j++){
            fscanf( inputfilepointer, "%d", &cpugrid[i*m+j] );
        }   
      }
    cudaMemcpy(gpugrid,cpugrid,n*m*sizeof(int),cudaMemcpyHostToDevice);
    fscanf( inputfilepointer, "%d", &srcx );
    fscanf( inputfilepointer, "%d", &srcy );
    fscanf( inputfilepointer, "%d", &destx );
    fscanf( inputfilepointer, "%d", &desty );
    fscanf( inputfilepointer, "%d", &Q );
    src.left = srcx;
    src.right= srcy;
    dest.left = destx;
    dest.right = desty; 
    struct node *cpunodematrix,*gpunodematrix;
    cpunodematrix = (node*)malloc(n*m*sizeof(node));
    cudaMalloc(&gpunodematrix,(n*m)*sizeof(node));
    //printf("hi");
    //bharath<<<1,1>>>();
    //cudaDeviceSynchronize();
    //printf("gi");
    initialize<<<n,m>>>(gpunodematrix,n,m,srcx,srcy);
    cudaMemcpy(cpunodematrix,gpunodematrix,n*m*sizeof(struct node),cudaMemcpyDeviceToHost);
    bool* visited;
    cudaMalloc(&visited,n*m*sizeof(bool));
    int* pushpq;
    cudaMalloc(&pushpq,8*sizeof(int));
    //initialisation done
    depth=0;
    //printf("Q %d\n",Q);
    for(int itr=0;itr<Q;itr++){
    //fout<<"inside the main gpu loop"<<endl;
        int op;
          fscanf( inputfilepointer, "%d", &op );
          
        //fout<<op<<endl;
        if(op==7){
           // printf("op %d\n",op);
            if(depth == 0){
        //fout<<"hola1"<<endl;
                astargpulevelone<<<1,1>>>(gpunodematrix,gpugrid, srcx,srcy, destx,desty,n,m,visited,pushpq); 
                cudaMemcpy(cpunodematrix,gpunodematrix,n*m*sizeof(struct node),cudaMemcpyDeviceToHost);
                //fout<<"exited astarone"<<endl;
                // setpushpq<<<1,8>>>(pushpq);
                // cudaDeviceSynchronize();
                // astargpuleveltwo<<<1,1>>>(gpunodematrix,gpugrid,destx,desty,pushpq,n,m,4,0,visited);
                
                //fout<<"hola2"<<endl;
                depth++;
            }
            if(cpunodematrix[destx*m+desty].g==FLT_MAX){
                fout<<"The destination node is not found"<<endl;
                continue;
            }
            fout<<"The destination node is found"<<endl; 
            path_trace2(cpunodematrix, dest,0,n,m); 
            fout<<"---------------------------------------------"<<endl;
            

            continue;
        }
    
        int edges;
        fscanf( inputfilepointer, "%d", &edges );
        for(int itr1=0;itr1<edges;itr1++){
            int x,y,e;
            fscanf( inputfilepointer, "%d", &x );
              fscanf( inputfilepointer, "%d", &y );
            fscanf( inputfilepointer, "%d", &e );
            cpugrid[x*m+y] = e; 
            int num =0;
            int xx[8] = {-1, 0, 1, 0,1,1,-1,-1};
            int yy[8] = {0, 1, 0, -1,1,-1,1,-1};
            for(int it=0;it<8;it++){
                int a,b;
                a= x + xx[it];
                b = y + yy[it];
                if(a<0||a>=n){
                    continue;
                }
                if(b<0||b>=m){
                    continue;
                }
                if(cpugrid[a*m+b] != -1){
                    num++;
                }
            }
            if(num == 0){
                Nodematrixtrivial<<<1,1>>>(gpunodematrix,gpugrid,x,y,e,destx,desty,n,m);
                cudaDeviceSynchronize();
                continue;
            }
            Nodematrixupdategpulevelone<<<1,1>>>(gpunodematrix,gpugrid,x,y,e,destx,desty,n,m,visited,pushpq);
            cudaDeviceSynchronize();
        }
        cudaMemcpy(cpunodematrix,gpunodematrix,n*m*sizeof(node),cudaMemcpyDeviceToHost);
        fout<<"Edges added"<<endl;
        fout<<"---------------------------------------------"<<endl;
    }
    //event2 -ended
cudaError_t err = cudaGetLastError();
      if ( err != cudaSuccess )
   {
      printf("CUDA Error: %s\n", cudaGetErrorString(err));
      return 0;
   }
    cudaEventRecord(stop1,0);
    cudaEventSynchronize(stop1);
    cudaEventElapsedTime(&milliseconds1, start1, stop1);
    printf("Time taken by GPU to execute is: %.6f ms\n", milliseconds1);
    
    //event-2 ended
    //event-3 starts

    cudaEvent_t start2, stop2;
    cudaEventCreate(&start2);
    cudaEventCreate(&stop2);
    float milliseconds2 = 0;
    cudaEventRecord(start2,0);

    fout<<"GPU(sequential) OUTPUT"<<endl;
    fclose(inputfilepointer);
    inputfilepointer    = fopen( inputfilename , "r");
    fscanf( inputfilepointer, "%d", &n );      //scaning for number of rows
    fscanf( inputfilepointer, "%d", &m );
    int *cpugrid2,*gpugrid2;
    cpugrid2 = (int*)malloc(n*m*sizeof(int));
    cudaMalloc(&gpugrid2,n*m*sizeof(int));
    for(int i=0;i<n;i++){
        for(int j=0;j<m;j++){
            fscanf( inputfilepointer, "%d", &cpugrid2[i*m+j] );
        }   
      }
    cudaMemcpy(gpugrid2,cpugrid2,n*m*sizeof(int),cudaMemcpyHostToDevice);
    fscanf( inputfilepointer, "%d", &srcx );
    fscanf( inputfilepointer, "%d", &srcy );
    fscanf( inputfilepointer, "%d", &destx );
    fscanf( inputfilepointer, "%d", &desty );
    fscanf( inputfilepointer, "%d", &Q );
    src.left = srcx;
    src.right= srcy;
    dest.left = destx;
    dest.right = desty; 
    struct node *cpunodematrix2,*gpunodematrix2;
    cpunodematrix2 = (node*)malloc(n*m*sizeof(node));
    cudaMalloc(&gpunodematrix2,(n*m)*sizeof(node));
    //printf("hi");
    //bharath<<<1,1>>>();
    //cudaDeviceSynchronize();
    //printf("gi");
    initialize2<<<1,1>>>(gpunodematrix2,n,m,srcx,srcy);
    cudaMemcpy(cpunodematrix2,gpunodematrix2,n*m*sizeof(struct node),cudaMemcpyDeviceToHost);
    bool* visited2;
    cudaMalloc(&visited2,n*m*sizeof(bool));

    //initialisation done
    depth=0;
    //printf("Q %d\n",Q);
    for(int itr=0;itr<Q;itr++){
    //fout<<"inside the main gpu loop"<<endl;
        int op;
          fscanf( inputfilepointer, "%d", &op );
          
        //fout<<op<<endl;
        if(op==7){
           // printf("op %d\n",op);
            if(depth == 0){
        //fout<<"hola1"<<endl;
                astargpu<<<1,1>>>(gpunodematrix2,gpugrid2, srcx,srcy, destx,desty,n,m,visited2); 
                cudaMemcpy(cpunodematrix2,gpunodematrix2,n*m*sizeof(struct node),cudaMemcpyDeviceToHost);
                //fout<<"exited astarone"<<endl;
                // setpushpq<<<1,8>>>(pushpq);
                // cudaDeviceSynchronize();
                // astargpuleveltwo<<<1,1>>>(gpunodematrix,gpugrid,destx,desty,pushpq,n,m,4,0,visited);
                
                //fout<<"hola2"<<endl;
                depth++;
            }
            if(cpunodematrix2[destx*m+desty].g==FLT_MAX){
                fout<<"The destination node is not found"<<endl;
                continue;
            }
            fout<<"The destination node is found"<<endl; 
            path_trace2(cpunodematrix2, dest,0,n,m); 
            fout<<"---------------------------------------------"<<endl;
            

            continue;
        }
    
        int edges;
        fscanf( inputfilepointer, "%d", &edges );
        for(int itr1=0;itr1<edges;itr1++){
            int x,y,e;
            fscanf( inputfilepointer, "%d", &x );
              fscanf( inputfilepointer, "%d", &y );
            fscanf( inputfilepointer, "%d", &e );
            cpugrid2[x*m+y] = e; 
            int num =0;
            int xx[8] = {-1, 0, 1, 0,1,1,-1,-1};
            int yy[8] = {0, 1, 0, -1,1,-1,1,-1};
            for(int it=0;it<8;it++){
                int a,b;
                a= x + xx[it];
                b = y + yy[it];
                if(a<0||a>=n){
                    continue;
                }
                if(b<0||b>=m){
                    continue;
                }
                if(cpugrid2[a*m+b] != -1){
                    num++;
                }
            }
            if(num == 0){
                Nodematrixtrivial<<<1,1>>>(gpunodematrix2,gpugrid2,x,y,e,destx,desty,n,m);
                cudaDeviceSynchronize();
                continue;
            }
            Nodematrixupdategpu<<<1,1>>>(gpunodematrix2,gpugrid2,x,y,e,destx,desty,n,m,visited2);
            cudaDeviceSynchronize();
        }
        cudaMemcpy(cpunodematrix2,gpunodematrix2,n*m*sizeof(node),cudaMemcpyDeviceToHost);
        fout<<"Edges added"<<endl;
        fout<<"---------------------------------------------"<<endl;
    }
    //event2 -ended
    cudaError_t err2 = cudaGetLastError();
      if ( err2 != cudaSuccess )
   {
      printf("CUDA Error: %s\n", cudaGetErrorString(err2));
      return 0;
   }
    cudaEventRecord(stop2,0);
    cudaEventSynchronize(stop2);
    cudaEventElapsedTime(&milliseconds2, start2, stop2);
    printf("Time taken by GPU(sequential) to execute is: %.6f ms\n", milliseconds2);

    return 0;
}
