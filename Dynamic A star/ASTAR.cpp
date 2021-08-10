#include <bits/stdc++.h>
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






int main(){ 
    //event-1 start


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
}
